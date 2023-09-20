# 英語とドイツ語の Onset-Nucleus (ON)/Nucleous-Coda (NC) 規模の音と綴りの対応づけデータ

第40会認知科学会 (2023年) の発表に関連したデータと処理系の公開

# Perl scripts

[0] データ処理のためのscripts

- [CMUPD のARPBBET を IPA に変換する Perl script](bin/convert-ARPABET-to-IPA.pl)
- [IPA表記と slash表記の対からON対を抽出する Perl script](bin/extract-paired-units.pl)
- [ON区切りをNC区切りに変換する Perl script](bin/convert-ON-to-NC.pl)

ON-NC converter のGerman 対応は今のところ不完全

# データ

## 英語 data

[CMU Pronouncing Dictionary (CMUPD)](http://www.speech.cs.cmu.edu/cgi-bin/cmudict) から発音と綴りの対応関係をする抽出ための Excel 作業本:

- [英語 (all) spell-sound ON対応づけデータ](English/base-English-spell-sound-ON-pairs-r6.xlsx)
- [英語 (1k most commons) spell-sound ON対応づけデータ (1k most common words 版) ](English/base-mc1k-English-spellsound-ON-pairs-r6.xlsx)

[1] から構築したSpell-Sound のON対応 (whole-word, 1-gram, 2-gram, 3-gram):

- [英語 (all) whole](English/source-ON-pairs-bundled-r6e.csv)
- [英語 (all) 1-gram](English/data-English-spell-sound-ON-pairing-r6e-1gram.xlsx)
- [英語 (all) 2-gram](English/data-English-spell-sound-ON-pairing-r6e-2gram.xlsx)
- [英語 (all) 3-gram](English/data-English-spell-sound-ON-pairing-r6e-3gram.xlsx)

[2] から構築したSpell-Sound ON対応 (1-gram, 2-gram, 3-gram):

- [英語 (1k most commons) 1,2,3-gram](English/data-mc1k-English-spell-sound-ON-pairing-r6e-ngram.xlsx)

[3] ON対応から自動生成したNC対応

- [英語 (all) whole word](English/source-Engish-NC-pairs-r6f.csv)
- [英語 (all) 1-gram](English/data-English-spell-sound-NC-pairing-r6f-1gram.xlsx)

ON=>NCの自動変換の精度は100%ではないため，若干の誤りが含まれる可能性が大．

[4] ON対応 (1gram) とNC対応 (1gram) から合成したONC対応 (2gram規模)

- [英語 spell.size で層別化した版](English/instances-ONC-NC-append-spell-size-classified.xlsx)
- [英語 spell.size で層別化していない版](English/instances-ONC-NC-append-spell-size-classified.xlsx)

合成法は NC に ON を prepend する方法と， ON に NC を append する方法とがあり，このデータは後者の方法で生成した．

## ドイツ語データ

[5] 1k most common words のドイツ語版の，発音と綴りの対応関係をする抽出ための Excel 作業本:

- [ドイツ語 (1k most commons) spell-sound 対応づけデータ](German/base-mc1k-German-spell-sound-ON-pairs-r1.xlsx)

[6] から構築したドイツ語の spell-sound 対応 (1-gram, 2-gram, 3-gram):

- [ドイツ語 (1k most commons) 1,2,3-gram](German/data-mc1k-German-spell-sound-ON-pairing-r1a-ngram.xlsx)


# 論文/paper

- [PDF](https://www.jcss.gr.jp/meetings/jcss2023/proceedings/pdf/JCSS2023_P3-026.pdf)

# ポスター/poster

- [PDF](https://www.dropbox.com/scl/fi/6ih342ehd5ph30wf2mnhg/kuroda-jcss40-poster.pdf?rlkey=0ho95h7c190hros5rq2d4bc62&dl=0)


# Resources

## 1k most common words

- [1k most common words (site)](https://1000mostcommonwords.com/)
