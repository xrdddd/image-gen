# Installing coremltools

Since you're in a conda environment, here are the best options:

## Option 1: Using Conda (Recommended for you)

Since you're in `(base)` conda environment:

```bash
conda install -c conda-forge coremltools
```

Or if that doesn't work:

```bash
conda install -c apple coremltools
```

## Option 2: Using pip in Conda

```bash
# Make sure you're in your conda environment
conda activate base  # or your environment name

# Install with pip (conda's pip)
pip install "coremltools>=7.0"
```

## Option 3: Create a New Conda Environment

```bash
# Create a new environment for this project
conda create -n image-gen python=3.10
conda activate image-gen

# Install coremltools
pip install "coremltools>=7.0"
```

## Option 4: Use pip with --user flag

```bash
pip install --user "coremltools>=7.0"
```

## Option 5: Use pip with --break-system-packages (if needed)

```bash
pip install --break-system-packages "coremltools>=7.0"
```

## Verify Installation

After installing, verify it works:

```bash
python3 -c "import coremltools; print(coremltools.__version__)"
```

You should see a version number (7.0 or higher).

## Then Run Quantization

Once coremltools is installed:

```bash
npm run quantize-models
```

Or:

```bash
python3 scripts/quantize_models.py
```

## Troubleshooting

### "zsh: 7.0 not found"
- Use quotes: `pip install "coremltools>=7.0"` (not `>=7.0`)

### Permission errors
- Use `--user` flag: `pip install --user "coremltools>=7.0"`
- Or use conda: `conda install -c conda-forge coremltools`

### Conda environment issues
- Make sure you're in the right environment: `conda activate base`
- Or create a new environment for this project
