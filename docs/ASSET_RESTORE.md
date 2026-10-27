# Asset restoration

Checked: 2026-10-27. Project: `Game Development\Games - Letta Collaborations\Xogot\xogot---sushi-restaurant`.

This document records how to restore omitted assets after cloning the code. It does not move or delete any file, and is not by itself a deletion approval. Git push and remote LFS availability are checked separately.

## Code and Git-managed assets

Repository: https://github.com/MarcoPaoletta/xogot---sushi-restaurant

Recorded branch: `main`. Documentation baseline commit: `2213ef4b92a320ccd12a2402c1e69690a4fca002`.

1. Clone the repository and select the documented code revision.
2. Install Git LFS if this repository uses it, then run `git lfs pull`. A pointer file is not the model itself.
3. Restore any omitted paths listed below without changing their directory names.
4. Open the matching engine version, allow imports to rebuild and validate the main scene and materials.
5. Installed private development methodology, editor caches and credentials are not runtime assets and must not be distributed with source code.

## Runtime asset paths omitted from ordinary Git

This list follows the configured main scene/autoload resources through scene/resource/script references. Tool, test, probe, temporary and evidence-only paths are excluded. It is not a recursive scan of caches or binary models.

No existing asset referenced by the inspected active text-resource graph was outside the Git file list. Restore the Git-managed assets first.

## Git LFS asset inventory

No Git LFS-managed working asset path was reported by the local Git metadata inspection.

## Production provenance and rebuild instructions

* `README.md`
* `assets/Sushi Restaurant Kit - May 2023/LICENSE.txt`
* `assets/Ultimate Food Pack - Oct 2019/License.txt`
* `docs/GDD.md`

## Owner-confirmed provider account restoration

On 2026-10-27 Marco explicitly confirmed that generated models remain downloadable from his original Tripo, Meshy, Hyper3D and other provider accounts. Use the original account library and the exact model/export names in this project. Missing direct URLs or task IDs are not a cleanup blocker under that instruction. No current API download test is claimed. Retrieve the final rigged/animated export and textures, not a static preview or a new generation. Keep the destination names unchanged and reapply the recorded import, animation, scale and postprocess steps.

## Outstanding verification

No unresolved active text-resource path was identified in this documentation pass. Complete the code push and any remote Git/LFS check before marking the project ready. Original production footage and local history are separate from model downloads.
