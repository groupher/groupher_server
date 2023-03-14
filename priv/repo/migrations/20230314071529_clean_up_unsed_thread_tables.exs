defmodule GroupherServer.Repo.Migrations.CleanUpUnsedThreadTables do
  use Ecto.Migration

  def change do
    alter table(:cited_artiments) do
      remove(:meetup_id)
    end

    alter table(:articles_join_tags) do
      remove(:meetup_id)
    end

    alter table(:abuse_reports) do
      remove(:meetup_id)
    end

    alter table(:article_collects) do
      remove(:meetup_id)
    end

    alter table(:article_upvotes) do
      remove(:meetup_id)
    end

    alter table(:pinned_comments) do
      remove(:meetup_id)
    end

    alter table(:comments) do
      remove(:meetup_id)
    end

    alter table(:articles_users_emotions) do
      remove(:meetup_id)
    end

    alter table(:pinned_articles) do
      remove(:meetup_id)
    end

    drop_if_exists table("cms_repo_builders")
    drop_if_exists table("meetup_documents")
    drop_if_exists table("cms_meetups")
  end
end
