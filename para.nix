# The PARA skeleton of the knowledge vault and the taxonomy shared with the
# home directory. lib/para.nix checks the values; README.md explains them.
#
#   roles       the PARA roles, each with its definition
#   folders     the vault's top-level folders: NN_Name, numbered in tens by
#               the flow, so a new folder fits in without renumbering
#     role      one of roles; each role has exactly one folder
#     lint      markdownlint profile of the folder: agent | forge | hybrid | off
#   kinds       kinds of content a folder of the home directory can hold
#   ideaStatus  the maturity of an idea in order, each { name; meaning; }
#               with its exit criterion
#   content     what a visible file in a PARA folder may be (T6-m)
#     formats   extension (lowercase, no dot) -> class: note | illustration |
#               raster (an illustration with a size limit) | page (an
#               artefact with a Content-Security-Policy) | asset (a page's
#               .css or .js); anything else is not content
#     rasterKiB the size limit of a raster illustration
{
  roles = {
    inbox = "Capture: unsorted items awaiting triage, emptied quickly.";
    ideas = "Pre-projects: ideas collected and sharpened until they become a project or a resource, or are dropped.";
    projects = "Short-term efforts with a defined goal and end state.";
    areas = "Standing responsibilities kept coherent with no end date; never done, only the current best answer until superseded.";
    resources = "Topics, interests and reference material that may be useful later; no action implied.";
    archive = "Inactive material worth returning to or citing: closed projects with their lessons, closed cards, retired conventions and decisions with their reasons, and snapshots of content the vault does not track.";
    scratchpad = "Experiments and temporary notes, Markdown only; outside the flow.";
  };

  folders = {
    "00_Inbox" = {
      role = "inbox";
      lint = "hybrid";
    };
    "10_Ideas" = {
      role = "ideas";
      lint = "hybrid";
    };
    "20_Projects" = {
      role = "projects";
      lint = "hybrid";
    };
    "30_Areas" = {
      role = "areas";
      lint = "hybrid";
    };
    "40_Resources" = {
      role = "resources";
      lint = "hybrid";
    };
    "90_Archive" = {
      role = "archive";
      lint = "off"; # not maintained, so not linted
    };
    "99_Scratchpad" = {
      role = "scratchpad";
      lint = "hybrid";
    };
  };

  kinds = {
    document = "Records and papers: letters, invoices, contracts, manuals, forms.";
    book = "Books and other long texts to read.";
    audiobook = "Books to listen to.";
    music = "Music and other audio meant for listening.";
    picture = "Photos, scans and other still images.";
    video = "Recordings and other moving images.";
    archive = "Cold storage: inactive material kept out of the way.";
  };

  ideaStatus = [
    {
      name = "seed";
      meaning = "A hunch or a keyword. Exit: a core sentence can be written.";
    }
    {
      name = "exploring";
      meaning = "The question is known; material is being collected. Exit: the core stays stable across two visits.";
    }
    {
      name = "shaped";
      meaning = "A clear statement and a known next move. Exit: a decision is made.";
    }
    {
      name = "promoted";
      meaning = "Became a project or a resource; the note moves there.";
    }
    {
      name = "dropped";
      meaning = "Not worth pursuing; the note moves to the archive with the reason.";
    }
  ];

  content = {
    formats = {
      md = "note";
      txt = "note";
      svg = "illustration";
      png = "raster";
      html = "page";
      css = "asset";
      js = "asset";
    };
    rasterKiB = 512;
  };
}
