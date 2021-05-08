# 河東セミナーニュース bot の仕様

## クロールの仕様

10 分ごとに[河東セミナーニュース](https://www.ms.u-tokyo.ac.jp/~yasuyuki/news.htm)と[どうでもよい記事](https://www.ms.u-tokyo.ac.jp/~yasuyuki/misc.htm)をクロールし、ニュース部分に当たる部分を取り出し、新しいニュースがあったら Tweet する。

ただしこれだけだと問題があって、 *訂正を反映できない* 。 Twitter は tweet を修正できない。河東先生が後から「これは書くべきじゃなかった、文言を訂正しよう」とニュース部分に変更を加えたとして、安直な仕様であると、その変更についていけない。これは先生にとっては懸念されるところであろうと思われる。

そこで次のようにすることにした。 10 分ごとのクロールをしたタイミングの処理を述べる。以下では集合に記号をおく。

> $A = $ 河東セミナーニュースをクロールする直前の news の集合
>
> $A' = $ クロールした直後の news の集合
>
> $B = $ その時点での @kawahigashinews の直近 100 件の tweet の集合[^1]

[^1]: [原理的には 200 件までいけるらしい](https://developer.twitter.com/en/docs/tweets/timelines/api-reference/get-statuses-user_timeline.html) (2018-01-17 現在)

$A, A', B$ を取得後、以下の処理を順番に実行する。

1. $A \setminus A'$ の元について、対応する $B$ の元が存在するならば、削除する(ツイ消しをする)。
2. $A' \setminus A$ の元について、対応する新規ツイートをする。

河東セミナーニュースを訂正した際は、 1. も 2. も実行されることになる。順序は担保されないものの、常に最新の記述が TL に並ぶことになる。 Twitter は文言を訂正できない以上、これが最善かと思う[^2]。

[^2]: なお、年が変更になった時点も想定して対応してある。少々 Twitter API や ms サーバが死んでも動き続けるロバストなものを目指した。

## news から tweet への変換について

### 概略

まず news を Nokogiri で判定する。 xpath で `<p>` を取り出し、0 文字目が `・` があるかどうかを判定する。 news であると判定したら、`<p>` の text を本文とし、冒頭の `・` と、文中の改行コードと前後の空白を削除する。その後文末の日付を正規表現で取得し、日付を `@date` とする。そして文末の日付を本文から削除し、本文を `@text` とする。また本文に貼られたリンク先 URLs を Nokogiri で取得し、 `@urls` とし、別途管理する。 tweet する際は `@date` + `@text` + `@urls` を適宜整形しながら順に並べ、 tweet 用の本文とする。

どうでもよい記事についても、前半の処理が `<li>` 用になるだけで、あとはほとんど同様である。

### 例

以下、 [2018 年のニュース](http://www.ms.u-tokyo.ac.jp/~yasuyuki/news18.htm)を seed にした例を挙げる。

基本的には、日付が先に来て、文章が続き、 URL が続く。

```html
<p>・<a href="http://www.icm2018.org/portal/en/home">ICM 2018</a>での講演を終えました．
講演者だけに見えるデジタルタイマーがありましたが，時間切れの3秒前に終わりました．
講演のPDFファイルは<a href="rio2018.pdf">こちら</a>にあります．
(8/3/2018)
```

> 08/03: ICM 2018での講演を終えました．講演者だけに見えるデジタルタイマーがありましたが，時間切れの3秒前に終わりました．講演のPDFファイルはこちらにあります． http://www.icm2018.org/portal/en/home http://www.ms.u-tokyo.ac.jp/~yasuyuki/rio2018.pdf

URL は href が相対 URL の場合は絶対 URL に直してあるし、 Amazon などで使われる日本語を含む URL にも(よほどエスケープに困らない限りは)対応しているはずである。

項目全体が Twitter の投稿限界文字数を超過する場合、本文を限界に収まるまで削る。

```html
<p>・Springerの展示ブースに行ったら，展示されている本の中に<a href="https://www.springer.com/la/book/9783319143002">私の薄い本</a>がありました．Springer の知り合いにこれは私の本だと言ったら，私が来ることがわかっていたから展示商品の中に入れておいたのだと言われました．
Scholze の論文が載っている<a href="https://www.springer.com/mathematics/journal/11537">Japan. J. Math.</a>の号もたくさんありました．彼がFields賞を取る確信があったので，あらかじめ日本からたくさん送っておいたとのことです．彼がサインして明日来場者に配るそうです．
(8/1/2018)
```

> 08/01: Springerの展示ブースに行ったら，展示されている本の中に私の薄い本がありました．Springer の知り合いにこれは私の本だと言ったら，私が来ることがわかっていたから展示商品の中に入れておいたのだと言われました．Scholze の論文が載って… https://www.springer.com/la/book/9783319143002 https://www.springer.com/mathematics/journal/11537

URL は先頭から最大 4 つまで載せる。それ以上は本文を削りすぎると判断して、載せないことにした。

```html
<p>・2018年Fields賞は
<a href="https://www.dpmms.cam.ac.uk/~cb496/">Caucher Birkar</a>,
<a href="https://people.math.ethz.ch/~afigalli/">Alessio Figalli</a>,
<a href="http://www.math.uni-bonn.de/people/scholze/">Peter Scholze</a>,
<a href="http://math.stanford.edu/~akshay/">Akshay Venkatesh</a>
に授与されました．Scholze, Venkateshは<a href="http://www.ms.u-tokyo.ac.jp/~toshi/jjm/JJMJ/JJM_JHP/contents/jjm-takagi_jp.htm">高木レクチャー</a>をしています．
また，Chern Medal は<a href="https://ja.wikipedia.org/wiki/%E6%9F%8F%E5%8E%9F%E6%AD%A3%E6%A8%B9">柏原正樹</a>氏に贈られました．
(8/1/2018)
```

> 08/01: 2018年Fields賞はCaucher Birkar,Alessio Figalli,Peter Scholze,Akshay Venkateshに授与されました．Scholze, Venkateshは高木レクチャーをしています．また，Chern Medal は柏原正樹氏に… https://www.dpmms.cam.ac.uk/~cb496/ https://people.math.ethz.ch/~afigalli/ http://www.math.uni-bonn.de/people/scholze/ http://math.stanford.edu/~akshay/

### 免責事項

河東セミナーニュースのエンコーディングは EUC-JP であるが、 parse する段階で Ruby で UTF-8 に変換して文字列を処理している。現代の文字列の標準は UTF-8 であるし、一部の gem に文字列を渡す際に UTF-8 が要求されるからである。そのため **最終出力が文字化けすることを完全に避けることはできない** 。実際 5 年分テストして 1 箇所文字化けし、どうしようもなかったものもある。もしかしたら(大変失礼であるものの)人名で発生してしまうかもしれない。そうなってら該当者の方には申し訳がない。

`twitter` gem の問題により、「$C^*$-環」などと書くときに使う `*` の文字を本文に含むツイートをするのは、現時点(2021-05-08)では困難である。そこで、 **本文中の `*` は全角の `＊` に変更してツイートする** ことにした。詳しくは、[該当する pull-request](https://github.com/kazunetakahashi/kawahigashi-news/pull/2) に書いた。

## 技術についてのメモ

全体の流れとしては [Nokogiri](https://nokogiri.org) でスクレイピングして [Clockwork](https://github.com/Rykian/clockwork) で定期的にクロールし、 [Twitter gem](https://github.com/sferik/twitter) で [REST API](https://developer.twitter.com/en/docs.html) を叩くだけである。

### Ruby における正規表現による取得

Perl 由来のメソッドではなく `match` メソッドを使用した。

### URL の短縮について

よく知られる通り、 Twitter は t.co による短縮 URL が導入されているが、日本語の短縮ができない。調べたら以下の奥村先生のページがヒットした。

- [非 ASCII 文字を含む URL のエンコード](https://oku.edu.mie-u.ac.jp/~okumura/javascript/encodeURI.html)

これに加え [Addressable](https://github.com/sporkmonger/addressable) という gem を見つけて解決した。

### ツイートの文字数のカウント

現在の Twitter は文字数のカウントが若干ややこしくなっている。大雑把に言えば「半角では 280 文字まで、全角では 140 文字まで」である。素朴にやるなら以下の方法がある。

- [Rubyでツイートの文字数を数える](https://qiita.com/yuip/items/a3c2048a374c151c8f72)

ところがこの方法では [Encoding::UndefinedConversionError](https://docs.ruby-lang.org/ja/latest/class/Encoding=3a=3aUndefinedConversionError.html) が生じることがわかった[^3]。

[^3]: 2018 年の河東セミナーニュースをテストして判明。エラーを吐くので避けるほかあるまい。

よく調べると、公式に提供されている [twitter-text](https://github.com/twitter/twitter-text/tree/master/rb) gem で文字カウントができることがわかった。これを使用することにした。この際、筆者の環境では libidn が必要であった。

```ruby
[16] pry(main)> Twitter::TwitterText::Validation.parse_tweet("「 1 歩音超え、 2 歩無間、 3 歩絶刀……！」 『無明三段突き』！ 」")
=> {:weighted_length=>65,
 :valid=>true,
 :permillage=>232,
 :valid_range_start=>0,
 :valid_range_end=>37,
 :display_range_start=>0,
 :display_range_end=>37}
```

これで二分探索することにした。

## 補足

### アイコンについて

現在(2021-05-08)の河東セミナーニュース bot の Twitter アイコンは、 [IPAex ゴシック](https://ipafont.ipa.go.jp)を Mac に入れて 3 分くらいで作成した。

## 大規模な改定記録

- 初版: 2019-01-19 by @kazunetakahashi 日記に書いていた内容。
- 第 2 版： 2021-05-08 by @kazunetakahashi 現状の仕様に合わせ、レポジトリの内部のドキュメントとしてふさわしい表現に改めた(改めきれていないかもしれない)。
