/// Shared domain models, enums, constants, and pure-calculation utilities
/// used identically by employee_app and admin_panel.
library shared;

export 'src/constants/app_constants.dart';
export 'src/constants/firestore_collections.dart';

export 'src/enums/attendance_action_type.dart';
export 'src/enums/attendance_day_state.dart';
export 'src/enums/attendance_status.dart';
export 'src/enums/integrity_result.dart';
export 'src/enums/user_role.dart';

export 'src/models/assignment.dart';
export 'src/models/attendance_action_record.dart';
export 'src/models/attendance_day.dart';
export 'src/models/attendance_event.dart';
export 'src/models/employee.dart';
export 'src/models/shift.dart';
export 'src/models/work_location.dart';

export 'src/utils/attendance_calculations.dart';
export 'src/utils/company_time.dart';
export 'src/utils/geo_utils.dart';
