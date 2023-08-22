# 英語とドイツ語の Onset-Nucleus 規模の音と綴りの対応づけデータ

第40会認知科学会 (2023年) の発表に関連したデータの公開

# データ

## 英語 data

[CMU Pronouncing Dictionary (CMUPD)](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) から発音と綴りの対応関係をする抽出ための Excel 作業本:

- [英語 (all) spell-sound ON対応づけデータ](base-English-ipa-spell-ON-pairs-r6.xlsx)
- [英語 (1k most commons) spell-sound ON対応づけデータ (1k most common words 版) ](base-English-ipa-spell-ON-pairs-r6-1k-mc.xlsx)

[1] から構築したSpell-Sound ON対応 (whole-word, 1-gram, 2-gram, 3-gram):

- [英語 (all) whole word](base-ON-pairs-bundled-r6e.csv)
- [英語 (all) 1-gram](data-English-spell-sound-ON-pairing-r6e-1gram.xlsx)
- [英語 (all) 2-gram](data-English-spell-sound-ON-pairing-r6e-2gram.xlsx)
- [英語 (all) 3-gram](data-English-spell-sound-ON-pairing-r6e-3gram.xlsx)

[2] から構築したSpell-Sound ON対応 (1-gram, 2-gram, 3-gram):

- [英語 (1k most commons) 1,2,3-gram](data-English-spell-sound-ON-pairing-r6e-ngram-1k.xlsx)

[3] ON対応から自動生成したNC対応

- [英語 (all) whole word](base-ON-pairs-bundled-r6f.csv)
- [英語 (all) 1-gram](data-English-spell-sound-NC-pairing-r6f-1gram.xlsx)

## ドイツ語データ

[4] 1k most common words のドイツ語版の，発音と綴りの対応関係をする抽出ための Excel 作業本:

- [ドイツ語 (1k most commons) spell-sound 対応づけデータ](base-German-ipa-spell-ON-pairs-r1-1k-mc.xlsx)

[5] から構築したドイツ語の spell-sound 対応 (1-gram, 2-gram, 3-gram):

- [ドイツ語 (1k most commons) 1,2,3-gram](data-German-spell-sound-ON-pairing-r1a-ngram-1k.xlsx)

# Perl scripts

[6] データ処理のためのscripts

- [CMUPD のARPBBET を IPA に変換する Perl script](bin/convert-ARPABET-to-IPA.pl)
- [IPA表記と slash表記の対からON対を抽出する Perl script](bin/extract-paired-units.pl)

# Resources

## 1k most common words

- [1k most common words (site)](https://1000mostcommonwords.com/)

# 論文/paper

- [PDF](https://www.jcss.gr.jp/meetings/jcss2023/proceedings/pdf/X.pdf)

# ポスター/poster

- [PDF](https://www.dropbox.com/X)
