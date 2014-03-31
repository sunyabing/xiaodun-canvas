/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'i18n!accounts.statistics',
  'jquery', // $
  'jquery.ajaxJSON', // ajaxJSON
  'jqueryui/dialog', // /\.dialog/
  'jquery.instructure_misc_helpers' // replaceTags
], function(I18n, $) {

  $(document).ready(function() {
    $(".over_time_link").live('click', function(event) {
      event.preventDefault();
      var name = $(this).attr('data-name');
      var url = $.replaceTags($(".over_time_url").attr('href'), 'attribute', $(this).attr('data-key'));
      var $link = $(this);
      $link.text(I18n.t('loading_text', "正在加载..."));
      $.ajaxJSON(url, 'GET', {}, function(data) {
        $link.text(I18n.t('over_time_link', "超时"));
        $("#over_time_dialog .csv_url").attr('href', url + '.csv');
        populateDialog(data, name);
      }, function(data) {
        $link.text(I18n.t('loading_error', "错误"));
      });
    });
    function populateDialog(data_points, axis) {
      $("#over_time_dialog").dialog({
        width: 630,
        height: 330,
        title: I18n.t('title_data_point_over_time', "%{data_point} 超时", {data_point: axis})
      });

      // google dependencies declared in views/acccounts/statistics since google.load uses document.write :(
      var data = new google.visualization.DataTable();
      data.addColumn('date', I18n.t('heading_date', '日期'));
      data.addColumn('number', axis || I18n.t('heading_value', "值"));
      data.addColumn('string', 'title1');
      data.addColumn('string', 'text1');
      
      var rows = []
      $.each(data_points, function() {
        var date = new Date();
        date.setTime(this[0]);
        rows.push(
          //this ends up being [(a date), (the number of pageViews on that date), "an annotation tile, (if any)", ""]
          [date, this[1], undefined, undefined]
        )
      });
      
      data.addRows(rows);

      var chart = new google.visualization.AnnotatedTimeLine(document.getElementById('over_time'));
      chart.draw(data, {displayAnnotations: false});
    }
  });
});