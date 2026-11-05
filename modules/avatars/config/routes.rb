Rails.application.routes.draw do
  # Update my avatar
  scope "my" do
    resource :avatar, controller: "avatars/my_avatar", as: "edit_my_avatar", only: %i[update destroy] do
      put :preset, on: :member
    end
  end

  # Neurvo: preset avatar images for the picker
  get "/avatars/presets/:key", controller: "avatars/presets", action: :show, as: "avatar_preset",
                               constraints: { key: /avatar-\d{2}/ }, defaults: { format: "png" }

  # Get the current avatar
  get "/users/:id/avatar", controller: "avatars/avatar", action: :show, as: "user_avatar"

  # Update another user's avatar
  scope "users/:id" do
    resource :avatar, controller: "avatars/users", as: "edit_user_avatar", only: %i[show update destroy] do
      put :preset, on: :member
    end
  end
end
