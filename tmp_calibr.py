# Calibration check: with kAcceptanceThreshold = 0.90, how many test images pass?
total = 596
correct = 577
wrong = 19

# From predictions.csv analysis:
# - All wrong: max confidence 0.8234 (none >= 0.90)
# - Correct: 512/596 >= 0.95, 18 more in 0.8-0.95, 20 in 0.5-0.7, 3 in <0.5
# At 90%: accepts 512/596 = 86% (all >=0.95, none of the 0.8-0.95 correct ones?)
# Let me recount with >=0.90
import csv
with open('paper_results/produce/predictions.csv') as f:
    rows = list(csv.DictReader(f))

accept_90 = [r for r in rows if float(r['confidence']) >= 0.90]
correct_90 = [r for r in accept_90 if r['correct'] == '1']
wrong_90 = [r for r in accept_90 if r['correct'] == '0']

print('At 90%% threshold:')
print('  Total accepted:', len(accept_90))
print('  Correct accepted:', len(correct_90))
print('  Wrong accepted:', len(wrong_90))
print('  % correct among accepted:', round(len(correct_90)/len(accept_90)*100, 1) if accept_90 else 0)

# Also check: what % of all test images pass?
print('  % of all images accepted:', round(len(accept_90)/total*100, 1))
