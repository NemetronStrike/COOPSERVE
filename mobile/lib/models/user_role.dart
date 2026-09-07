enum UserRole { customer, worker, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.worker:
        return 'Worker';
      case UserRole.admin:
        return 'Cooperative Admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.customer:
        return 'Book household and community services';
      case UserRole.worker:
        return 'Manage your jobs and earnings';
      case UserRole.admin:
        return 'Oversee workers, bookings and disputes';
    }
  }
}
