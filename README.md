# VTL4004
VTL Interpreter for Intel 4004 Evaluation Board

This document is written mostly in Japanese.
If necessary, please use a translation service such as DeepL (I recommend this) or Google.

![](images/title.jpg)
![](images/mandel.jpg)

## 概要
自作の4004実験用ボードにVTLを実装しました．


## VTLの仕様
### オリジナルのVTLとの違い
- 変数は-32768〜32767
  - それに伴い，行番号も32767まで
- IF文あり
- エラー判断あり
- 16進数値(0xxxx)
- 16進表示2桁(?$=)
- 16進表示4桁(??=)

### 実装しようと思ったけどペンディング
- PEEK(@(address)右辺)
- POKE(@(address)左辺)

### 未実装
- 行の編集(挿入，削除等)
  - 最初から行番号昇順のプログラムを入力が前提
- 配列
- 乱数
- 乗算の上位16bit
- メモリ上限管理('*')

## 実験用ボードの仕様
- CPU: Intel 4004
- Clock: 740kHz
- DATA RAM: 4002-1 x 2 + 4002-2 x 2 (計320bit x 4)
- Program Memory
  - ROM: AT28C64B (8k x 8bit EEPROM)
    - 000H〜EFFHの3.75KB利用可能
  - RAM: HM6268(4k x 4bit SRAM)x 2個
    - 物理メモリ F00H〜FFDHの254byte x 16バンク
      (上記を論理メモリ 000H〜FDFHにマッピングしてアクセスします．)
- 通信ポート: 9600bps Software Serial UART (TTL level)

## ToDO
- プリント基板作成

## 動画
Youtubeで関連動画を公開しています．
- https://www.youtube.com/@ryomukai/videos

## ブログ
関連する情報が書いてあるかも．
- https://blog.goo.ne.jp/tk-80

## 参考にした文献，サイト
### 4004関連開発事例
- [Intel 4004  50th Anniversary Project](https://www.4004.com/)
  - https://www.4004.com/busicom-replica.html
  - http://www.4004.com/2009/Busicom-141PF-Calculator_asm_rel-1-0-1.txt
- https://github.com/jim11662418/4004-SBC
- https://www.cpushack.com/mcs-4-test-boards-for-sale
- https://github.com/novi/4004MainBoard


### データシート
- http://www.bitsavers.org/components/intel/
- https://www.intel-vintage.info/intelmcs.htm

### 開発環境
- [The Macroassembler AS](http://john.ccac.rwth-aachen.de:8000/as/)
- [Intel 4004 emulator assembler disassembler](http://e4004.szyc.org/)


## 更新履歴
- 2023/3/11: 初版公開
