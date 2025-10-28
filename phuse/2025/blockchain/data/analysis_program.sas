/* Statistical Analysis Program - Demographics Summary */
/* Analysis ID: ANALYSIS_001 */
/* Date: 2024-10-18 */

proc means data=dm n mean std min max;
  var age;
  class sex;
run;

proc freq data=dm;
  tables sex*race / nocol nopercent;
run;

