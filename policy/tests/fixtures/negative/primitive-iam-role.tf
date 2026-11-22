resource "google_project_iam_member" "editor" {
  project = "example"
  role    = "roles/editor"
  member  = "serviceAccount:example@example.iam.gserviceaccount.com"
}
