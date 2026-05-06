# student-images/

This folder is **for your own custom fish photos** for Part B of the lab. Drop JPGs here; pavo's `getimg()` and `segment_fish()` will find them.

## Folder layout

```
images/
├── demo/                    ← the 3 demo fish for Part A (don't touch)
├── student-fish/            ← pre-loaded starter species per lineage
│   ├── chaetodontidae/      ← 5 butterflyfish, ready to use
│   ├── pomacanthidae/       ← 5 angelfish
│   ├── balistidae/          ← 5 triggerfish
│   └── acanthuridae/        ← 5 surgeonfish
└── student-images/          ← THIS FOLDER — your own uploads go here
```

## Naming rule

Use **lowercase, hyphenated** filenames so paths stay clean:

✅ Good: `chaetodon-auriga.jpg`, `pomacanthus-imperator.jpg`
❌ Bad: `Chaetodon Auriga.JPG` (capitals + space), `IMG_1234.jpeg`

Format: `genus-species.jpg`. For multiple photos of the same species, append `-1`, `-2`, etc.

## How to load your fish in R

After you've added a JPG to this folder:

```r
seg_path <- segment_fish("images/student-images/your-fish.jpg")
my_fish  <- getimg(seg_path)
```

(See the student guide for the full Part B walkthrough.)
