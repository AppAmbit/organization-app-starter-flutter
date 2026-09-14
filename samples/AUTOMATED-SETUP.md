# Automated backend setup

Connect the AppAmbit MCP server to your AI assistant once, paste one prompt, and the backend
configures itself.

**The assistant does:**

- Creates the 4 CMS content types
- Creates every content entry, in dependency order
- Resolves `@content_type:lookup_key` tokens into real entry ids
- Writes `APPAMBIT_APPKEY_*` into your `.env`
- Verifies the import by re-querying the CMS

**You still do:**

- Create the app in the AppAmbit dashboard (needs a human)
- Flip two fields to *many* relations — [step 4 checkpoint](#the-checkpoint-is-a-real-stop)
- Upload images to the media library
- Add your Firebase / APNs push credentials
- Run the app

> New to the data model? Read [**README.md**](README.md) first — it explains the four content types,
> how they render, and the image slots. This page is only about automating the import.

---

## 1. Get a token

1. Open the AppAmbit dashboard → **Settings → AI Assistant**.
2. Create a personal access token and copy it.

The token is scoped to your team. Treat it like a password.

## 2. Connect the MCP server

**Claude Code** — from the repo root:

```sh
claude mcp add --transport http appambit https://appambit.com/mcp/appambit --header "Authorization: Bearer YOUR_TOKEN"
```

Add `--scope project` to write it into the repo's `.mcp.json` and share the server with your team —
the server, not the token. See the warning below.

**Any other MCP client** (Cursor, VS Code, Claude Desktop, Windsurf):

1. Copy [`.mcp.json.example`](../.mcp.json.example) to `.mcp.json`.
2. Drop your token in.
3. Point the client at it.

The shape is the same everywhere:

```json
{
  "mcpServers": {
    "appambit": {
      "type": "http",
      "url": "https://appambit.com/mcp/appambit",
      "headers": { "Authorization": "Bearer YOUR_TOKEN" }
    }
  }
}
```

> ⚠️ **Your token is not a repo file.** `.mcp.json` is gitignored for this reason. If you clone a
> fork that already has one, replace the token with your own — a stranger's token points at a
> stranger's team.

**Check it works.** Ask the assistant: *"list my AppAmbit apps"*. You should get your apps with
their `app_key`s. If not, the token is wrong or was not sent as a `Bearer` header.

## 3. Create the app in the dashboard

The MCP server can read and write your team's data, but it **cannot create an app**. Do that
yourself:

- One app per platform — iOS and Android are separate apps.
- You do not need to copy the keys by hand. The prompt below reads them back and writes `.env` for
  you.

## 4. Paste the prompt

Fill in the two bracketed values and paste it into your assistant with this repo open. It is short
because the assistant reads the rest from the repo:

````text
Set up my AppAmbit backend with the MCP tools. Read the "Rules" section of
samples/AUTOMATED-SETUP.md first and follow it.

App name: [My App Name]
Dataset: samples/datasets/[blog].json

1. list-apps-tool -> find my app_key(s), write them into .env.
2. Create the 4 content types from samples/schema/content-types.json in one call.
3. STOP: tell me to switch the two fields to MANY relations, and wait for me to confirm.
4. Create the dataset entries in import_order, resolving the @ tokens as you go.
5. Verify, then tell me what is left for me to do by hand.
````

---

## Rules

The prompt points here on purpose — this is the part that has to be right, and it does not change
between runs.

### `.env`

- Copy `.env.example` first if `.env` does not exist.
- Set only `APPAMBIT_APPKEY_ANDROID` and `APPAMBIT_APPKEY_IOS`.

### Content types

- Pass the `content_types` array from `samples/schema/content-types.json` **unchanged**.
- Use a single `create-content-type-tool` call.

### The checkpoint is a real stop

`create-content-type-tool` has no `multiple` flag, so both relation fields come out single-valued.
Every section holding more than one card fails validation until you fix it. Fifteen seconds of work
in the dashboard:

> Content types → **Feed Carousel** → field `carousel` → set to a **many** relation.
> Repeat for **Content Details** → field `content`.

### Entries

- One `create-content-entry-tool` call per content type.
- Follow the dataset's `import_order`:
  `content_detail_items` → `content_details` → `carousel_items` → `feed_carousel`.
- Each `data` goes as a JSON string, with `status: "published"` and `locale: "en"`.

### Relations

- Datasets store `@content_type:lookup_key` tokens, not ids. For `content_details` the key is its
  `title`.
- **There is no update-entry tool.** Keep the `lookup_key → id` map from each call and substitute
  *before* creating the entry that references it.
- `import_order` is bottom-up, so every target already exists in time.

Full explanation in [README.md → Resolve the relations](README.md#step-4--resolve-the-relations).

### Verify

- `query-content-tool` on `feed_carousel` and `carousel_items`. Counts should match the dataset, and
  no field should still contain an `@` token.

### Two apps

Content types and entries are per-app. Repeat the content step for the second `app_key` — iOS and
Android are separate apps.

---

## 5. After the run

```sh
flutter run
```

The home feed should show your imported content on launch.

- **A section shows a single card instead of a carousel?** The step 4 checkpoint was skipped. Fix the
  field in the dashboard, then re-run step 5 of the prompt for `feed_carousel` only.
- **Cards have no images?** Expected — that is deliberate. See
  [README.md → Images](README.md#images) for the slot sizes and what each one should show.

---

## Other prompts worth keeping

**Switch the app to a different vertical:**

```text
Import samples/datasets/movies.json into my AppAmbit app <app_key> using the MCP tools, following
import_order and resolving @content_type:lookup_key tokens to real ids as you go. The content types
already exist — do not recreate them. Tell me which of the old entries are now orphaned.
```

**Generate a dataset for my own vertical:**

```text
Read samples/datasets/blog.json to learn the shape, then write samples/datasets/<mine>.json for a
[real-estate listings] app: 5 feed sections (one featured, two small, one large collection, one
banner), 12 carousel_items, 2 content_details with 4-5 blocks each. Keep the same schema, the same
@token relation style, and the same images block with slots and aspect ratios. Then import it.
```

**Health check:**

```text
Using the AppAmbit MCP tools, check app <app_key>: verify-sdk-integration-tool, list-crashes-tool
for the last 7 days, and query-content-tool for feed_carousel. Tell me if anything looks wrong.
```

---

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| Assistant says it has no AppAmbit tools | MCP server not connected, or the client was not restarted | Restart the client after editing `.mcp.json` |
| `401` / empty app list | Token is wrong, expired, or belongs to another team | Generate a new one in **Settings → AI Assistant** |
| Relation validation errors on `feed_carousel` | The step 4 checkpoint was skipped | Set `carousel` to a **many** relation |
| Entries created but the feed is empty | Entries are `draft` | Only `published` reaches the SDK — republish them |
| `@carousel_items:...` still visible in the data | Entries were created out of order | Recreate them following `import_order` |
| Cards render without images | Expected | Upload art and set `image` / `banner_image` |

---

**Next:** [README.md](README.md) for the data model and image slots · [root README](../README.md)
for building, running and shipping the app.
