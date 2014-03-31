define [
  'jquery'
  'underscore'
  '../start_app'
  'ember'
  '../shared_ajax_fixtures'
  '../../controllers/screenreader_gradebook_controller'
  'vendor/jquery.ba-tinypubsub'
], ($, _, startApp, Ember, fixtures, SRGBController) ->

  App = null
  originalIsDraft = null
  originalWeightingScheme = null

  fixtures.create()
  clone = (obj) ->
    Em.copy obj, true

  setup = (isDraftState=false) ->
    window.ENV.GRADEBOOK_OPTIONS.draft_state_enabled = isDraftState
    originalWeightingScheme =  window.ENV.GRADEBOOK_OPTIONS.group_weighting_scheme
    App = startApp()
    Ember.run =>
      @srgb = SRGBController.create()
      @srgb.set('model', {
        enrollments: Ember.ArrayProxy.create(content: clone fixtures.students)
        assignment_groups: Ember.ArrayProxy.create(content: clone fixtures.assignment_groups)
        submissions: Ember.ArrayProxy.create(content: [])
        sections: Ember.ArrayProxy.create(content: clone fixtures.sections)
      })

  teardown = ->
    window.ENV.GRADEBOOK_OPTIONS.draft_state_enabled = false
    window.ENV.GRADEBOOK_OPTIONS.group_weighting_scheme = originalWeightingScheme
    Ember.run App, 'destroy'

  module 'screenreader_gradebook_controller',
    setup: ->
      setup.call this
    teardown: ->
      teardown.call this


  test 'calculates students properly', ->
    equal @srgb.get('students.length'), 10
    equal @srgb.get('students.firstObject').name, fixtures.students[0].user.name

  test 'calculates assignments properly', ->
    equal @srgb.get('assignments.length'), 7
    ok !@srgb.get('assignments').findBy('name', 'Not Graded')
    equal @srgb.get('assignments.firstObject').name, fixtures.assignment_groups[0].assignments[0].name

  test 'studentsHash returns the expected hash', ->
    _.each @srgb.studentsHash(), (obj) =>
      strictEqual @srgb.get('students').findBy('id', obj.id), obj

  test 'assignmentGroupsHash retuns the expected hash', ->
    _.each @srgb.assignmentGroupsHash(), (obj) =>
      strictEqual @srgb.get('assignment_groups').findBy('id', obj.id), obj

  test 'student objects have isLoaded flag set to true once submissions are loaded', ->
    @srgb.get('students').forEach (s) ->
      equal Ember.get(s, 'isLoaded'), true

  test 'displayName is hiddenName when hideStudentNames is true', ->
    @srgb.set('hideStudentNames', true)
    equal @srgb.get('displayName'), "hiddenName"
    @srgb.set('hideStudentNames', false)
    equal @srgb.get('displayName'), "name"

  test 'updateSubmission attaches the submission to the student', ->
    student = clone fixtures.students[0].user
    submission = clone fixtures.submissions[student.id].submissions[0]

    @srgb.updateSubmission submission, student
    strictEqual student["assignment_#{submission.assignment_id}"], submission

  test 'studentsInSelectedSection is the same as students when selectedSection is null', ->
    ok (!@srgb.get('selectedSection'))
    deepEqual @srgb.get('students'), @srgb.get('studentsInSelectedSection')

  test 'selecting a section filters students properly', ->
    Ember.run =>
      @srgb.set('selectedSection', @srgb.get('sections.lastObject'))
    equal @srgb.get('studentsInSelectedSection.length'), 6
    equal @srgb.get('studentsInSelectedSection.firstObject').name, 'Buffy'

  test 'sorting assignments alphabetically', ->
    Ember.run =>
      @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'alpha'))
    equal @srgb.get('assignments.firstObject.name'), 'Apples are good'
    equal @srgb.get('assignments.lastObject.name'), 'Z Eats Soup'

  test 'sorting assignments by due date', ->
    Ember.run =>
      @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'due_date'))
    equal @srgb.get('assignments.firstObject.name'), 'Can You Eat Just One?'
    equal @srgb.get('assignments.lastObject.name'), 'Drink Water'

  test 'sorting assignments by position', ->
    Ember.run =>
      @srgb.set('assignmentSort', @srgb.get('assignmentSortOptions').findBy('value', 'assignment_group'))
    equal @srgb.get('assignments.firstObject.name'), 'Z Eats Soup'
    equal @srgb.get('assignments.lastObject.name'), 'Da Fish and Chips!'

  test 'correctly determines if prev/next student exists on load', ->
    equal @srgb.get('studentIndex'), -1
    equal @srgb.get('disablePrevStudentButton'), true
    equal @srgb.get('ariaDisabledPrevStudent'), 'true'
    equal @srgb.get('disableNextStudentButton'), false
    equal @srgb.get('ariaDisabledNextStudent'), 'false'

  test 'correctly determines if prev/next assignment exists on load', ->
    equal @srgb.get('assignmentIndex'), -1
    equal @srgb.get('disablePrevAssignmentButton'), true
    equal @srgb.get('ariaDisabledPrevAssignment'), 'true'
    equal @srgb.get('disableNextAssignmentButton'), false
    equal @srgb.get('ariaDisabledNextAssignment'), 'false'

  test 'updates assignment groups and weightingScheme when event is triggered', ->
    window.ENV.GRADEBOOK_OPTIONS.group_weighting_scheme = 'whoa'
    Ember.run =>
      $.publish('assignment_group_weights_changed', assignmentGroups: Ember.copy(fixtures.assignment_groups, true).slice(0,1))

    equal @srgb.get('weightingScheme'), 'whoa', 'weightingScheme was updated'
    equal @srgb.get('assignment_groups.length'), 1, 'assignment_groups was updated'

  module 'screenreader_gradebook_controller: with selected student',
    setup: ->
      setup.call this
      Ember.run =>
        student = @srgb.get('students.firstObject')
        @srgb.set('selectedStudent', student)
    teardown: ->
      teardown.call this

  test 'selectedSubmission should be null when just selectedStudent is set', ->
    strictEqual @srgb.get('selectedSubmission'), null

  test 'correctly determines index and if prev/next student exists for first student', ->
    equal @srgb.get('studentIndex'), 0
    equal @srgb.get('disablePrevStudentButton'), true
    equal @srgb.get('ariaDisabledPrevStudent'), 'true'
    equal @srgb.get('disableNextStudentButton'), false
    equal @srgb.get('ariaDisabledNextStudent'), 'false'

  test 'correctly determines index and if prev/next student exists for second student', ->
    Ember.run =>
      students = @srgb.get('students')
      @srgb.set('selectedStudent', students.objectAt(1))
    equal @srgb.get('studentIndex'), 1
    equal @srgb.get('disablePrevStudentButton'), false
    equal @srgb.get('ariaDisabledPrevStudent'), 'false'
    equal @srgb.get('disableNextStudentButton'), false
    equal @srgb.get('ariaDisabledNextStudent'), 'false'

  test 'correctly determines index and if prev/next student exists for last student', ->
    Ember.run =>
      student = @srgb.get('students.lastObject')
      @srgb.set('selectedStudent', student)
    equal @srgb.get('studentIndex'), 9
    equal @srgb.get('disableNextStudentButton'), true
    equal @srgb.get('ariaDisabledNextStudent'), 'true'
    equal @srgb.get('disablePrevStudentButton'), false
    equal @srgb.get('ariaDisabledPrevStudent'), 'false'

  module 'screenreader_gradebook_controller: with selected student and selected assignment',
    setup: ->
      setup.call this
      Ember.run =>
        @student = @srgb.get('students.firstObject')
        @assignment = @srgb.get('assignments.firstObject')
        @srgb.set('selectedStudent', @student)
        @srgb.set('selectedAssignment', @assignment)

    teardown: ->
      teardown.call this

  test 'assignmentDetails is computed properly', ->
    ad = @srgb.get('assignmentDetails')
    selectedAssignment = @srgb.get('selectedAssignment')
    strictEqual ad.assignment, selectedAssignment
    strictEqual ad.cnt, 0

  test 'selectedSubmission is computed properly', ->
    selectedSubmission = @srgb.get('selectedSubmission')
    sub = _.find(fixtures.submissions, (s) => s.user_id == @student.id)
    submission = _.find(sub.submissions, (s) => s.assignment_id == @assignment.id)
    _.each submission, (val, key) =>
      equal selectedSubmission[key], val, "#{key} is the expected value on selectedSubmission"

  module 'screenreader_gradebook_controller: with selected assignment',
    setup: ->
      setup.call this
      @assignment = @srgb.get('assignments.firstObject')
      Ember.run =>
        @srgb.set('selectedAssignment', @assignment)

    teardown: ->
      Ember.run App, 'destroy'

  test 'correctly determines if prev/next assignment exists for first assignment', ->
    equal @srgb.get('assignmentIndex'), 0
    equal @srgb.get('disablePrevAssignmentButton'), true
    equal @srgb.get('ariaDisabledPrevAssignment'), 'true'
    equal @srgb.get('disableNextAssignmentButton'), false
    equal @srgb.get('ariaDisabledNextAssignment'), 'false'

  test 'correctly determines if prev/next assignment exists for second assignment', ->
    Ember.run =>
      assignments = @srgb.get('assignments')
      @srgb.set('selectedAssignment', assignments.objectAt(1))
    equal @srgb.get('assignmentIndex'), 1
    equal @srgb.get('disablePrevAssignmentButton'), false
    equal @srgb.get('ariaDisabledPrevAssignment'), 'false'
    equal @srgb.get('disableNextAssignmentButton'), false
    equal @srgb.get('ariaDisabledNextAssignment'), 'false'

  test 'correctly determines if prev/next assignment exists for last assignment', ->
    Ember.run =>
      assignment = @srgb.get('assignments.lastObject')
      @srgb.set('selectedAssignment', assignment)
    equal @srgb.get('assignmentIndex'), 6
    equal @srgb.get('disablePrevAssignmentButton'), false
    equal @srgb.get('ariaDisabledPrevAssignment'), 'false'
    equal @srgb.get('disableNextAssignmentButton'), true
    equal @srgb.get('ariaDisabledNextAssignment'), 'true'

  module 'screenreader_gradebook_controller:draftState',
    setup: ->
      setup.call this, true
      Em.run =>
        @srgb.get('assignment_groups').pushObject
          id: '100'
          name: 'Silent Assignments'
          position: 2
          assignments: [
            {
              id: '21'
              name: 'Unpublished Assignment'
              points_possible: 10
              grading_type: "percent"
              submission_types: ["none"]
              due_at: null
              position: 6
              assignment_group_id:'4'
              published: false
            }
          ]

    teardown: ->
      teardown.call this

  test 'calculates assignments properly', ->
    equal @srgb.get('assignments.length'), 7
    ok !@srgb.get('assignments').findBy('name', 'Unpublished Assignment')


  calc_stub = {
    group_sums: [
      {
        final:
          possible: 100
          score: 50
          submission_count: 10
          weight: 50
          submissions: []
        current:
          possible: 100
          score: 20
          submission_count: 5
          weight: 50
          submissions:[]
        group:
          id: "1"
      }
    ]
    final:
      possible: 100
      score: 90
    current:
      possible: 88
      score: 70
  }


  calc_stub_with_0_possible = {
    group_sums: [
      {
        final:
          possible: 0
          score: 50
          submission_count: 10
          weight: 50
          submissions: []
        current:
          possible: 0
          score: 20
          submission_count: 5
          weight: 50
          submissions:[]
        group:
          id: "1"
      }
    ]
    final:
      possible: 0
      score: 0
    current:
      possible: 0
      score: 0
  }

  calculationSetup = (calculationStub = calc_stub) ->
    App = startApp()
    Ember.run =>
      @srgb = SRGBController.create()
      @srgb.reopen
        calculate: ->
          calculationStub

      @srgb.set('model', {
        enrollments: Ember.ArrayProxy.create(content: clone fixtures.students)
        assignment_groups: Ember.ArrayProxy.create(content: clone fixtures.assignment_groups)
        submissions: Ember.ArrayProxy.create(content: [])
        sections: Ember.ArrayProxy.create(content: clone fixtures.sections)
      })

  module 'grade calc',
    setup: ->
      calculationSetup.call this

  test 'calculates final grade', ->
    equal @srgb.get('students.firstObject.total_percent'), 79.5

  module 'grade calc with 0s',
    setup: ->
      calculationSetup.call this, calc_stub_with_0_possible

  test 'calculates final grade', ->
    equal @srgb.get('students.firstObject.total_percent'), 0