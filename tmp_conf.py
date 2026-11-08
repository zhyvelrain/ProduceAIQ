import csv, collections

with open('paper_results/produce/predictions.csv') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

print('Total rows:', len(rows))
bins = collections.Counter()
for r in rows:
    conf = float(r['confidence'])
    if conf >= 0.95: bins['>=0.95'] += 1
    elif conf >= 0.8: bins['0.8-0.95'] += 1
    elif conf >= 0.7: bins['0.7-0.8'] += 1
    elif conf >= 0.5: bins['0.5-0.7'] += 1
    else: bins['<0.5'] += 1
print('Confidence distribution:', dict(bins))

others = [r for r in rows if r['predicted'] == 'OTHER']
print('Other predictions:', len(others))
if others:
    confs = [float(r['confidence']) for r in others]
    n = len(confs)
    med = sorted(confs)[n//2]
    print('Other confidence min/median/max:', min(confs), med, max(confs))
    print('Other conf >= 0.75:', sum(1 for c in confs if c >= 0.75))

wrong = [r for r in rows if r['correct'] == '0']
print('Wrong predictions:', len(wrong))
for r in wrong:
    fname = r['file'].split('\\')[-1]
    print('  %-40s true=%-15s pred=%-15s conf=%s' % (fname, r['true'], r['predicted'], r['confidence']))
