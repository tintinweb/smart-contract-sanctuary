pragma solidity ^0.4.19;
/*	The Hitchhiker&#39;s Guide to the Galaxy (H2G2), Version 1.0.42.000.000.The.Primary.Phase
/*	==============================================================================================	*/
/*	  http://remix.ethereum.org/#optimize=false&version=soljson-v0.4.19+commit.c4cbbb05.js			*/
/*	This contract MUST be compiled with OPTIMIZATION=NO via Solidity v0.4.19+commit.c4cbbb05		*/
/*	Attempting to compile this contract with any earlier or later  build  of  Solidity  will		*/
/*	result in Warnings and/or Compilation Errors. Turning  on  optimization  during  compile		*/
/*	will prevent the contract code from being able to Publish and Verify properly. Thus,  it		*/
/*	is imperative that this contract be compiled with optimization off using v0.4.19 of  the		*/
/*	Solidity compiler, more specifically: v0.4.19+commit.c4cbbb05.					        		*/
/*	==============================================================================================	*/
/*	THIS TOKEN IS PROUDLY BROUGHT TO YOU BY THE CAMPAIGN FOR REAL TIME  WITH  SLARTIBARTFAST		*/
/*	IN COOPERATION WITH THE CAMPAIGN TO SAVE THE HUMANS WITH  THE  DOLPHINS.  THIS  MAY  ALL		*/
/*	CEASE TO EXIST WITH THE DEATH OF AGRAJAG AT STAVROMULA BETA,  OR  SO  IT  WOULD  SEEM...		*/
/*	SHOUTOUT TO "THE DIGITAL VILLAGE"! 	http://www.tdv.com/											*/
/*										https://en.wikipedia.org/wiki/The_Digital_Village			*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Ethereum MainNet.											*/
/*	Token Name				:	The Hitchhiker&#39;s Guide to the Galaxy								*/
/*	Version Number			:	V1.0.42.000.000.The.Primary.Phase									*/
/*	Total Supply			:	42,000,000 Tokens													*/
/*	Contract Address		:	0xb957D92D7fEaE5be6877AA94997De6dcd36B65F4							*/
/*	Ticker Symbol			:	H2G2																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0x1f313f38d37705fb87feecf4e0dca4a95f74bd52							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0xeed85dd48475bad57a7b06aba4780ae47e8d3473b1ce4218c9c24994188d4d40	*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Ropsten Ethereum TestNet.									*/
/*	Token Name				:	The Hitchhiker&#39;s Guide to the Galaxy								*/
/*	Version Number			:	V1.0.42.000.000.The.Primary.Phase									*/
/*	Total Supply			:	42,000,000 Tokens													*/
/*	Contract Address		:	0xb957d92d7feae5be6877aa94997de6dcd36b65f4							*/
/*	Ticker Symbol			:	H2G2																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0x1f313f38d37705fb87feecf4e0dca4a95f74bd52							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0xf14d0a2d8a6616064a27f661696a7d991b174f2c6601250878d3d55dcaff4523	*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Rinkeby Ethereum TestNet.									*/
/*	Token Name				:	The Hitchhiker&#39;s Guide to the Galaxy								*/
/*	Version Number			:	V1.0.42.000.000.The.Primary.Phase									*/
/*	Total Supply			:	42,000,000 Tokens													*/
/*	Contract Address		:	0xb957d92d7feae5be6877aa94997de6dcd36b65f4							*/
/*	Ticker Symbol			:	H2G2																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0x1f313f38d37705fb87feecf4e0dca4a95f74bd52							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0xd5a46e0cf8e3e05b84f3cd334dc45a3b905fcb2b76da7816a4985c6b3ac52a79	*/
/*	==============================================================================================	*/
/*							:	The following are the details of this token as it appears			*/
/*							:	on the Kovan Ethereum TestNet.										*/
/*	Token Name				:	The Hitchhiker&#39;s Guide to the Galaxy								*/
/*	Version Number			:	V1.0.42.000.000.The.Primary.Phase									*/
/*	Total Supply			:	42,000,000 Tokens													*/
/*	Contract Address		:	0xb957d92d7feae5be6877aa94997de6dcd36b65f4							*/
/*	Ticker Symbol			:	H2G2																*/
/*	Decimals				:	18																	*/
/*	Creator Address			:	0x1f313f38d37705fb87feecf4e0dca4a95f74bd52							*/
/*	Via the Genesis Address	:	0x0000000000000000000000000000000000000000							*/
/*	Transaction				:	0x83a32aa85037e350a52f6679fa52bed2efc7f873890a77dfaf47f03e0f4c7a59	*/
/*	==============================================================================================	*/

/*
	This ERC20 Token: The Hitchhiker&#39;s Guide to the Galaxy (H2G2) is NOT meant to have any  intrinsic  (fundamental)  value  nor  any  monetary  value
	whatsoever. It is designed to honour the memory of Douglas Noel Adams. However, it is possible  that  this  token  may  accrue  value  over  time,
	although this is HIGHLY UNLIKELY. Any such valuation would likely be based entirely upon speculation, current market conditions,  the  actions  of
	other fanatical Douglas Adams fans (such as myself) and a myriad of other such  conditions  and/or  factors.  These  factors  and  conditions  may
	include, but are not limited to, the magnitude (quantity) and frequency (volume) of funds being traded for this token, if  any.  In  the  unlikely
	event that this token should gain monetary value at some future date, then a novel use of this token might  be  to  trade  value  and/or  pay  for
	memorabilia between fans and collectors of Douglas Adams memorabilia, publications and so forth. Again, do NOT count on this token to acquire  any
	value of any kind as it has been created solely for the purpose of honouring the memory of Douglas Adams. Should you decide to purchase this token
	which, again, is NOT recommended, then please be aware that they are non-refundable. See also the supplemental token: HHGTTG (h2g2),  as  detailed
	below. The supplemental token HHGTTG (h2g2) will be distributed via an airdop to the TOP 42 HOLDERS of this (The Hitchhiker&#39;s Guide to the  Galaxy
	[H2G2]) token. Whereas this (The Hitchhiker&#39;s Guide to the Galaxy [H2G2])token has a total supply of 42,000,000; the supplemental token will  have
	a total supply of ONLY 42 tokens @ 18 decimals and will be airdropped when greater than 55% of this  (The Hitchhiker&#39;s Guide to the Galaxy [H2G2])
	token has been distributed, however long that may take. Although these tokens,  The Hitchhiker&#39;s Guide to the Galaxy (H2G2) and HHGTTG (h2g2)  are
	not intended to have value, they may be acquired by sending eth to the contract  address  at a rate of 1000 H2G2 tokens per 1 eth and 1 h2g2 token
	per 1 eth. The price of h2g2 is intentionally set high to discourage purchase leaving a larger quantity for the airdrop (keep in mind  that  there
	exists a sum total of ONLY 42 h2g2 tokens and 42,000,000 H2G2 tokens). Note that the "ticker" symbols for these two tokens differ  only  in  case,
	with H2G2 being The Hitchhiker&#39;s Guide to the Galaxy token (42,000,000) and h2g2 being the HHGTTG token (42). No disrespect  is  intended  to  the
	memory of Douglas Noel Adams, nor his estate and heirs and neither to the BBC - all to whom  I  remain  thankful  for  these  wonderful  works  of
	artistic fiction. Now then, let&#39;s get on with the tribute:

	The day of 11 May 2001 would become one of the worst days of my life for that is the date on which Douglas Adams died of  heart  failure.  My  one
	true hero ceased to exist as did my hope of a further H2G2 (HG2G) novel, although Eoin Colfer would eventually pen  "And Another Thing",  it  just
	wasn&#39;t the same. If your interest in this token is piqued, then you will no doubt know WHY the Total Supply  is  42,000,000 Tokens.  The  original
	intent was to have the total supply limited to only 42 Tokens  with  18  decimal  places  resulting  in  the  ability  to  acquire  as  little  as
	.000000000000000001 Hitchhiker&#39;s Guide to the Galaxy (H2G2) Tokens. Setting the maximum  supply  to  only  42  would  have  severely  limited  the
	utility of this Token, as there are far more than 42 fans of Douglas Adams in this Universe. A supplemental token WILL be created which will  have
	a total supply of ONLY 42 tokens and will be distributed to the 42 highest holders of this token  (in an amount to be determined).  The  following
	text has been lifted from WikiPedia on 8 June 2018. To see the most recent version of this text, visit:
	https://en.wikipedia.org/wiki/Douglas_Adams

	Douglas Noel Adams (11 March 1952 – 11 May 2001) was an English author, scriptwriter, essayist, humorist, satirist and dramatist. Adams was author
	of The Hitchhiker&#39;s Guide to the Galaxy, which originated in 1978 as a BBC radio comedy before developing into a "trilogy" of five books that sold
	more than 15 million copies in his lifetime and generated a television series, several stage plays, comics, a computer game, and in 2005 a feature
	film. Adams&#39;s contribution to UK radio is commemorated in The Radio Academy&#39;s Hall of Fame. Adams also  wrote  Dirk  Gently&#39;s  Holistic  Detective
	Agency (1987) and The Long Dark Tea-Time of the Soul (1988), and co-wrote The Meaning of Liff (1983), The Deeper  Meaning  of  Liff  (1990),  Last
	Chance to See (1990), and three stories for the television series Doctor Who; he also served as script editor for the show&#39;s seventeenth season in
	1979. A posthumous collection of his works, including an unfinished novel, was published as The Salmon of Doubt in 2002. Adams was an advocate for
	environmentalism  and  conservation,  a  lover  of  fast  cars,  technological  innovation  and  the  Apple  Macintosh,  and  a  radical  atheist.

	Early life: Adams was born on 11 March 1952 to Janet (n&#233;e Donovan; 1927–2016) and Christopher Douglas Adams (1927–1985) in Cambridge, England. The
	Family moved to the East End of London a few months after his birth, where his sister, Susan, was born three years later. His parents divorced  in
	1957;   Douglas,  Susan,  and  their  mother  moved  to  an  RSPCA  animal  shelter  in  Brentwood,  Essex,  run  by  his  maternal  grandparents.

	Education: Adams attended Primrose Hill Primary School in Brentwood. At nine, he passed the entrance exam for  Brentwood  School,  an  independent
	school whose alumni include Robin Day, Jack Straw, Noel Edmonds, and David Irving. Griff Rhys Jones was a year below him, and he was in  the  same
	class as Stuckist artist Charles Thomson. He attended the prep school from 1959 to 1964, then the main school until  December 1970.  Adams  was  6
	feet (1.8 m) by age 12 and stopped growing at 6 feet 5 inches (1.96 m). His form master, Frank Halford, said his height had made him stand out and
	that he had been self-conscious about it. His ability to write stories made him well known in the school. He became the only student  ever  to  be
	awarded a ten out of ten by Halford for creative writing, something he remembered for the rest of his  life,  particularly  when  facing  writer&#39;s
	block. Some of his earliest writing was published at the school, such as a report on its photography club in The Brentwoodian in  1962,  or  spoof
	reviews in the school magazine Broadsheet, edited by Paul Neil Milne Johnstone, who later became a character in  The Hitchhiker&#39;s Guide.  He  also
	designed the cover of one issue of the Broadsheet, and had a letter and short story published in  The Eagle, the boys&#39;  comic,  in  1965.  A  poem
	entitled "A Dissertation on the task of writing a poem on a candle and an account of some of the difficulties thereto pertaining" written by Adams
	in January 1970, at the age of 17, was discovered in a cupboard at the school in early 2014. On the strength  of  a  bravura  essay  on  religious
	poetry that discussed the Beatles and William Blake, he was awarded an Exhibition in English at St John&#39;s College, Cambridge, going up in 1971. He
	wanted to join the Footlights, an invitation-only student comedy club that has  acted  as  a  hothouse  for  comic  talent.  He  was  not  elected
	immediately as he had hoped, and started to write and perform in revues with Will Adams (no relation) and Martin Smith,  forming  a  group  called
	"Adams-Smith-Adams", but became a member of the Footlights by 1973. Despite doing very little work—he recalled having completed  three  essays  in
	three years—he graduated in 1974 with a B.A. in English literature.

	Career: Writing: After leaving university Adams moved back to London, determined to break into TV and radio as a writer. An edited version of  the
	Footlights Revue appeared on BBC2 television in 1974. A version of the Revue performed live in London&#39;s West End led to Adams being discovered  by
	Monty Python&#39;s Graham Chapman. The two formed a brief writing partnership, earning Adams a writing credit in  episode 45  of  Monty Python  for  a
	sketch called "Patient Abuse". The pair also co-wrote the "Marilyn Monroe" sketch which appeared on the soundtrack album of Monty Python  and  the
	Holy Grail. Adams is one of only two people other than the original Python members to get a writing credit (the other being Neil Innes). Adams had
	two brief appearances in the fourth series of Monty Python&#39;s Flying Circus. At the beginning of episode 42,  "The Light Entertainment War",  Adams
	is in a surgeon&#39;s mask (as Dr. Emile Koning, according to on-screen captions), pulling on gloves, while  Michael  Palin  narrates  a  sketch  that
	introduces one person after another but never gets started. At the beginning of episode 44, "Mr. Neutron", Adams is dressed in a pepper-pot outfit
	and loads a missile onto a cart driven by Terry Jones, who is calling for scrap metal ("Any old iron..."). The  two  episodes  were  broadcast  in
	November 1974. Adams and Chapman also attempted non-Python projects, including Out of the Trees. At this point Adams&#39;s career stalled; his writing
	style was unsuited to the then-current style of radio and TV comedy. To make ends meet he took a series of  odd  jobs,  including  as  a  hospital
	porter, barn builder, and chicken shed cleaner. He was employed as a bodyguard by a Qatari family, who had made their fortune in oil. During  this
	time Adams continued to write and submit sketches, though few were accepted. In 1976 his  career  had  a  brief  improvement  when  he  wrote  and
	performed Unpleasantness at Brodie&#39;s Close at the Edinburgh Fringe festival. By Christmas, work had dried up again, and a depressed Adams moved to
	live with his mother. The lack of writing work hit him hard and low confidence became a feature of Adams&#39;s life; "I have terrible periods of  lack
	of confidence. I briefly did therapy, but after a while I realised it was like a farmer complaining about the weather. You can&#39;t fix the weather –
	you just have to get on with it". Some of Adams&#39;s early radio work included sketches for The Burkiss Way in 1977 and The News Huddlines.  He  also
	wrote, again with Chapman, the 20 February 1977 episode of Doctor on the Go, a sequel to the Doctor in the House television comedy  series.  After
	the first radio series of The Hitchhiker&#39;s Guide became successful, Adams was made a BBC radio producer, working on Week Ending  and  a  pantomime
	called Black Cinderella Two Goes East. He left after six months to become the script editor for Doctor Who. In 1979  Adams  and  John Lloyd  wrote
	scripts for two half-hour episodes of Doctor Snuggles: "The Remarkable Fidgety River" and  "The Great Disappearing Mystery"  (episodes  eight  and
	twelve). John Lloyd was also co-author of two episodes from the original Hitchhiker radio series ("Fit the Fifth" and "Fit the Sixth", also  known
	as "Episode Five" and "Episode Six"), as well as The Meaning of Liff and The Deeper Meaning of Liff.

	The Hitchhiker&#39;s Guide to the Galaxy: The Hitchhiker&#39;s Guide to the Galaxy was a concept for a science-fiction  comedy  radio  series  pitched  by
	Adams and radio producer Simon Brett to BBC Radio 4 in 1977. Adams came up with an outline for a pilot episode, as well as  a  few  other  stories
	(reprinted in Neil Gaiman&#39;s book Don&#39;t Panic: The Official Hitchhiker&#39;s Guide to the Galaxy Companion) that could be used in the series. According
	to Adams, the idea for the title occurred to him while he lay drunk in a field in Innsbruck, Austria, gazing at the stars. He was carrying a  copy
	of the Hitch-hiker&#39;s Guide to Europe, and it occurred to him that "somebody ought to write a Hitchhiker&#39;s Guide to the Galaxy". He later said that
	the constant repetition of this anecdote had obliterated his memory of the actual event. Despite the original outline, Adams was said to  make  up
	the stories as he wrote. He turned to John Lloyd for help with the final two episodes  of  the  first  series.  Lloyd  contributed  bits  from  an
	unpublished science fiction book of his own, called GiGax. Very little of Lloyd&#39;s material survived in later adaptations of Hitchhiker&#39;s, such  as
	the novels and the TV series. The TV series was based on the first six radio episodes, and sections contributed by Lloyd were largely  re-written.
	BBC Radio 4 broadcast the first radio series weekly in the UK in March and April 1978. The series was distributed in the United States by National
	Public Radio. Following the success of the first series, another episode was recorded and broadcast, which was commonly  known  as  the  Christmas
	Episode. A second series of five episodes was broadcast one per night, during the week of 21–25 January 1980. While working on  the  radio  series
	(and with simultaneous projects such as The Pirate Planet) Adams developed problems keeping to writing deadlines that got worse  as  he  published
	novels. Adams was never a prolific writer and usually had to be forced by others to do any writing. This included being locked in  a  hotel  suite
	with his editor for three weeks to ensure that So Long, and Thanks for All the Fish was completed. He was quoted as saying,  "I love deadlines.  I
	love the whooshing noise they make as they go by." Despite the difficulty with deadlines, Adams wrote five novels  in  the  series,  published  in
	1979, 1980, 1982, 1984, and 1992. The books formed the basis for other adaptations, such as three-part comic book  adaptations  for  each  of  the
	first three books, an interactive text-adventure computer game, and a photo-illustrated edition, published in 1994. This latter edition featured a
	42 Puzzle designed by Adams, which was later incorporated into paperback covers of the first four Hitchhiker&#39;s novels (the paperback for the fifth
	re-used the artwork from the hardback edition). In 1980 Adams began attempts to turn the first Hitchhiker&#39;s novel  into  a  film,  making  several
	trips to Los Angeles, and working with Hollywood studios and potential producers. The next year, the radio series  became  the  basis  for  a  BBC
	television mini-series broadcast in six parts. When he died in 2001 in California, he had been trying again to get the movie project started  with
	Disney, which had bought the rights in 1998. The screenplay got a posthumous re-write by Karey Kirkpatrick, and the resulting film was released in
	2005. Radio producer Dirk Maggs had consulted with Adams, first in 1993, and later in 1997 and 2000 about creating a third radio series, based  on
	the third novel in the Hitchhiker&#39;s series. They also discussed the possibilities of radio adaptations of the final two novels  in  the  five-book
	"trilogy". As with the movie, this project was realised only after Adams&#39;s death. The third series, The Tertiary Phase, was broadcast on BBC Radio
	4 in September 2004 and was subsequently released on audio CD. With the aid of a recording of his reading of Life, the Universe and Everything and
	editing, Adams can be heard playing the part of Agrajag posthumously. So Long, and Thanks for All the Fish and Mostly Harmless made up the  fourth
	and fifth radio series, respectively (on radio they were titled The Quandary Phase and The Quintessential Phase) and these were broadcast  in  May
	and June 2005, and also subsequently released on Audio CD. The last episode in the last series (with a new, "more upbeat" ending) concluded  with,
	"The very final episode of The Hitchhiker&#39;s Guide to the Galaxy by Douglas Adams is affectionately dedicated to its author."

	Dirk Gently series: Between Adams&#39;s first trip to Madagascar with Mark Carwardine in 1985, and their series of travels that formed the  basis  for
	the radio series and non-fiction book Last Chance to See, Adams wrote two other novels  with  a  new  cast  of  characters. Dirk Gently&#39;s Holistic
	Detective Agency was published in 1987, and was described by  its  author  as  "a kind of ghost-horror-detective-time-travel-romantic-comedy-epic,
	mainly concerned with mud, music and quantum mechanics". It was derived from two Doctor Who serials Adams had  written.  A  sequel,  The Long Dark
	Tea-Time of the Soul, was published a year later. This was an entirely original work, Adams&#39;s  first  since  So Long, and Thanks for All the Fish.
	After  the  book  tour,  Adams  set  off  on  his  round-the-world  excursion  which  supplied  him  with  the  material  for  Last Chance to See.

	Doctor Who: Adams sent the script for the HHGG pilot radio programme to the Doctor Who production office in 1978, and was  commissioned  to  write
	The Pirate Planet (see below). He had also previously attempted to submit a potential movie script, called "Doctor Who and the Krikkitmen",  which
	later became his novel Life, the Universe and Everything (which in turn became the third Hitchhiker&#39;s Guide radio series). Adams then went  on  to
	serve as script editor on the show for its seventeenth season in 1979. Altogether, he wrote three Doctor Who serials  starring  Tom Baker  as  the
	Doctor: "The Pirate Planet" (the second serial in the "Key to Time" arc, in season 16) "City of Death" (with  producer  Graham Williams,  from  an
	original storyline by writer David Fisher. It was transmitted under the pseudonym "David Agnew") "Shada" (only partially filmed; not televised due
	to industry disputes) The episodes authored by Adams are some of the few that were not novelised as Adams would not allow  anyone  else  to  write
	them, and asked for a higher price than the publishers were willing to pay. "Shada" was later adapted as a novel by  Gareth Roberts  in  2012  and
	"City of Death" and "The Pirate Planet" by James Goss in 2015 and 2017 respectively. Elements of Shada and City of Death were  reused  in  Adams&#39;s
	later novel Dirk Gently&#39;s Holistic Detective Agency, in particular the character of Professor Chronotis. Big Finish Productions eventually  remade
	Shada as an audio play starring Paul McGann as the Doctor. Accompanied by partially animated illustrations, it was webcast on the BBC  website  in
	2003, and subsequently released as a two-CD set later that year. An omnibus edition of this version was broadcast on  the  digital  radio  station
	BBC7 on 10 December 2005. In the Doctor Who 2012 Christmas episode The Snowmen, writer Steven Moffat  was  inspired  by  a  storyline  that  Adams
	pitched called The Doctor Retires.

	Music: Adams played the guitar left-handed and had a collection of twenty-four left-handed guitars when he died (having received his first  guitar
	in 1964). He also studied piano in the 1960s with the same teacher as Paul Wickens, the pianist who plays in Paul McCartney&#39;s band  (and  composed
	the music for the 2004–2005 editions of the Hitchhiker&#39;s Guide radio series). Pink Floyd and Procol Harum had important influence on Adams&#39;  work.

	Pink Floyd: Adams&#39;s official biography shares its name with the song  "Wish You Were Here"  by  Pink Floyd.  Adams  was  friends  with  Pink Floyd
	guitarist David Gilmour and, on Adams&#39;s 42nd birthday, he was invited to make a guest appearance at Pink Floyd&#39;s concert of  28  October  1994  at
	Earls Court in London, playing guitar on the songs "Brain Damage" and "Eclipse". Adams chose the name  for  Pink Floyd&#39;s 1994 album,  The Division
	Bell, by picking the words from the lyrics to one of its tracks, "High Hopes". Gilmour also performed at Adams&#39;s memorial  service  in  2001,  and
	what would have been Adams&#39;s 60th birthday party in 2012.
	
	Computer games and projects: Douglas Adams created an interactive fiction version of HHGG with Steve Meretzky from Infocom in  1984.  In  1986  he
	participated in a week-long brainstorming session with the Lucasfilm Games team for the game Labyrinth. Later he was  also  involved  in  creating
	Bureaucracy as a parody of events in his own life. Adams was a founder-director and Chief Fantasist of The Digital Village, a  digital  media  and
	Internet company with which he created Starship Titanic, a Codie Award-winning and BAFTA-nominated adventure game, which was published in 1998  by
	Simon & Schuster. Terry Jones wrote the accompanying book, entitled Douglas Adams&#39; Starship Titanic, since Adams was too busy  with  the  computer
	game to do both. In April 1999, Adams initiated the H2G2 collaborative writing project, an experimental attempt at  making  The Hitchhiker&#39;s Guide
	to the Galaxy a reality, and at harnessing the collective brainpower of the internet community. It was hosted by BBC Online from 2001 to 2011.  In
	1990, Adams wrote and presented a television documentary programme Hyperland which featured  Tom Baker  as  a  "software agent"  (similar  to  the
	assistant pictured in Apple&#39;s Knowledge Navigator video of future concepts  from  1987),  and  interviews  with  Ted Nelson,  the  co-inventor  of
	hypertext and the person who coined the term. Adams was an early adopter and advocate of hypertext.

	Personal beliefs and activism: Atheism and views on religion: Adams described himself as a "radical atheist", adding "radical" for emphasis so  he
	would not be asked if he meant agnostic. He told American Atheists that this conveyed the fact that he really meant it.  He  imagined  a  sentient
	puddle who wakes up one morning and thinks, "This is an interesting world I find myself in – an interesting hole I find myself in – fits me rather
	neatly, doesn&#39;t it? In fact it fits me staggeringly well, must have been made to have me in it!" to  demonstrate  his  view  that  the  fine-tuned
	Universe argument for God was a fallacy. He remained fascinated by religion because of its effect  on  human  affairs.  "I love to keep poking and
	prodding at it. I&#39;ve thought about it so much over the years that that fascination is bound to spill  over  into  my  writing."  The  evolutionary
	biologist and atheist Richard Dawkins uses Adams&#39;s influence to exemplify arguments for non-belief in  his  2006  book  The God Delusion.  Dawkins
	dedicated the book to Adams, whom he jokingly called "possibly [my] only convert" to atheism and  wrote  on  his  death  that  "Science has lost a
	friend, literature has lost a luminary, the mountain gorilla and the black rhino have lost a gallant defender."

	Environmental activism: Adams was also an environmental activist who campaigned on behalf  of  endangered  species.  This  activism  included  the
	production of the non-fiction radio series Last Chance to See, in which he and naturalist Mark Carwardine visited rare species such as the  kakapo
	and baiji, and the publication of a tie-in book of the same name. In 1992 this was made into a CD-ROM combination of audiobook, e-book and picture
	slide show. Adams and Mark Carwardine contributed the &#39;Meeting a Gorilla&#39; passage from Last Chance to See to the book The Great Ape Project.  This
	book, edited by Paola Cavalieri and Peter Singer, launched a wider-scale project in 1993, which calls for  the  extension  of  moral  equality  to
	include all great apes, human and non-human. In 1994, he participated in a climb of Mount Kilimanjaro while wearing a rhino suit for  the  British
	charity organisation Save the Rhino International. Puppeteer William Todd-Jones, who had originally worn the suit in the London Marathon to  raise
	money and bring awareness to the group, also participated in the climb wearing a rhino suit; Adams wore the suit while travelling to the  mountain
	before the climb began. About &#163;100,000 was raised through that event, benefiting schools in Kenya and a black rhinoceros preservation programme in
	Tanzania. Adams was also an active supporter of the Dian Fossey Gorilla Fund. Since 2003, Save the Rhino has held an annual Douglas Adams Memorial
	Lecture around the time of his birthday to raise money for environmental campaigns.

	Technology and innovation: Adams bought his first word processor in 1982, having considered one as early as 1979. His first purchase was  a  Nexu.
	In 1983, when he and Jane Belson went to Los Angeles, he bought a DEC Rainbow. Upon their return to England, Adams bought an Apricot, then  a  BBC
	Micro and a Tandy 1000. In Last Chance to See Adams mentions his Cambridge Z88, which he had taken to Zaire on a quest to find the northern  white
	rhinoceros. Adams&#39;s posthumously published work, The Salmon of Doubt, features several articles by him on the  subject  of  technology,  including
	reprints of articles that originally ran in MacUser magazine, and in The Independent on Sunday newspaper. In these Adams claims that  one  of  the
	first computers he ever saw was a Commodore PET, and that he had "adored" his Apple Macintosh ("or rather my family of however many Macintoshes it
	is that I&#39;ve recklessly accumulated over the years") since he first saw one at Infocom&#39;s offices in Boston in 1984. Adams  was  a  Macintosh  user
	from the time they first came out in 1984 until his death in 2001. He was the first person to buy a Mac in Europe (the  second  being  Stephen Fry
	– though some accounts differ on this, saying Fry bought his Mac first. Fry claims he was second to Adams).  Adams  was  also  an  "Apple Master",
	celebrities whom Apple made into spokespeople for its products (others included John Cleese and Gregory Hines). Adams&#39;s contributions  included  a
	rock video that he created using the first version of iMovie with footage featuring his daughter Polly. The video was available  on  Adams&#39;s  .Mac
	homepage. Adams installed and started using the first release of Mac OS X in the weeks leading up to his death. His very  last  post  to  his  own
	forum was in praise of Mac OS X and the possibilities of its Cocoa programming framework. He said it was "awesome...", which  was  also  the  last
	word he wrote on his site. Adams used email to correspond with Steve Meretzky in the early 1980s, during their collaboration on Infocom&#39;s  version
	of The Hitchhiker&#39;s Guide to the Galaxy. While living in New Mexico in 1993 he set up another e-mail address and began posting to his  own  USENET
	newsgroup, alt.fan.douglas-adams, and occasionally, when his computer was acting up, to the comp.sys.mac hierarchy. Challenges to the authenticity
	of his messages later led Adams to set up a message forum on his own website to avoid the issue. In 1996, Adams  was  a  keynote  speaker  at  the
	Microsoft Professional Developers Conference (PDC) where he described the personal computer as being a modelling device. The video of his  keynote
	speech is archived on Channel 9. Adams was also a keynote speaker for the April 2001 Embedded Systems Conference  in  San Francisco,  one  of  the
	major technical conferences on embedded system engineering.

	Personal life: Adams moved to Upper Street, Islington, in 1981 and to Duncan Terrace, a few minutes&#39; walk away, in the late 1980s.  In  the  early
	1980s Adams had an affair with novelist Sally Emerson, who was separated from her husband at that time. Adams later dedicated his  book  Life, the
	Universe and Everything to Emerson. In 1981 Emerson returned to her husband, Peter Stothard, a contemporary of Adams&#39;s  at  Brentwood School,  and
	later editor of The Times. Adams was soon introduced by friends to Jane Belson, with whom he later became romantically involved.  Belson  was  the
	"lady barrister" mentioned in the jacket-flap biography printed in his books during the mid-1980s ("He [Adams] lives  in  Islington  with  a  lady
	barrister and an Apple Macintosh"). The two lived in Los Angeles together during 1983 while Adams worked on  an  early  screenplay  adaptation  of
	Hitchhiker&#39;s. When the deal fell through, they moved back to London, and after several separations ("He is currently not certain where  he  lives,
	or with whom") and a broken engagement, they married on 25 November 1991. Adams and Belson had  one  daughter  together,  Polly Jane Rocket Adams,
	born on 22 June 1994, shortly after Adams turned 42. In 1999 the family moved from London to Santa Barbara, California, where they lived until his
	death. Following the  funeral,  Jane Belson  and  Polly Adams  returned  to  London.  Belson  died  on  7  September  2011  of  cancer,  aged  59.

	Death and legacy: Adams died of a heart attack on 11 May 2001, aged 49, after resting from his regular workout at  a  private  gym  in  Montecito,
	California. Adams had been due to deliver the commencement address at Harvey Mudd College on 13 May. His funeral was  held  on  16  May  in  Santa
	Barbara. His ashes were placed in Highgate Cemetery in  north  London  in  June  2002.  A  memorial  service  was  held  on  17 September 2001  at
	St Martin-in-the-Fields church, Trafalgar Square, London. This became the first church service broadcast live on the web by the  BBC.  Video clips
	of the service are still available on the BBC&#39;s website for download. One of his last public appearances was a talk given  at  the  University  of
	California, Santa Barbara, Parrots, the universe and everything, recorded days before his death. A full transcript of the talk is  available,  and
	the university has made the full video available on YouTube. Two days before Adams died, the Minor Planet Center announced the naming of  asteroid
	18610 Arthurdent. In 2005, the asteroid 25924 Douglasadams was named in his memory. In May 2002,  The Salmon of Doubt  was  published,  containing
	many short stories, essays, and letters, as well as eulogies from Richard Dawkins, Stephen Fry (in the UK edition), Christopher Cerf  (in  the  US
	edition), and Terry Jones (in the US paperback edition). It also includes eleven chapters of his unfinished novel, The Salmon of Doubt, which  was
	originally intended to become a new Dirk Gently novel, but might have later become the sixth Hitchhiker novel. Other events  after  Adams&#39;s  death
	included a webcast production of Shada, allowing the complete story to be told, radio dramatisations of the final three books in the  Hitchhiker&#39;s
	series, and the completion of the film adaptation of The Hitchhiker&#39;s Guide to the Galaxy. The film, released in 2005, posthumously credits  Adams
	as a producer, and several design elements – including a head-shaped planet seen near the end of the  film  –  incorporated  Adams&#39;s  features.  A
	12-part radio series based on the Dirk Gently novels was announced in 2007. BBC Radio 4 also commissioned a third Dirk Gently radio  series  based
	on the incomplete chapters of The Salmon of Doubt, and written by Kim Fuller; but this was dropped in favour of a BBC TV series based on  the  two
	completed novels. A sixth Hitchhiker novel, And Another Thing..., by Artemis Fowl author Eoin Colfer, was released on 12 October  2009  (the  30th
	anniversary of the first book), published with the support of Adams&#39;s estate. A BBC Radio 4 Book at Bedtime adaptation  and  an  audio  book  soon
	followed. On 25 May 2001, two weeks after Adams&#39;s death, his fans organised a tribute known as Towel Day, which has been observed every year since
	then. In 2011, over 3,000 people took part in a public vote to choose the subjects of People&#39;s Plaques in Islington; Adams received 489 votes.  On
	11 March 2013, Adams&#39;s 61st birthday was celebrated with an interactive Google Doodle. In 2018, John Lloyd presented an hour-long episode  of  the
	BBC Radio Four documentary Archive on 4, discussing Adams&#39; private papers,  which  are  held  at  St John&#39;s College,  Cambridge.  The  episode  is
	available online. A street in S&#227;o Jos&#233;, Santa Catarina, Brazil is named in Adams&#39; honour.

	The following text has been lifted from WikiPedia on 14 June 2018. To see the most recent version of this text, visit:
	https://en.wikipedia.org/wiki/The_Hitchhiker%27s_Guide_to_the_Galaxy
	The Hitchhiker&#39;s Guide to the Galaxy (sometimes referred to as HG2G, HHGTTG or H2G2 is a comedy science fiction series created  by  Douglas Adams.
	Originally a radio comedy broadcast on BBC Radio 4 in 1978, it was later adapted to other formats, including stage shows, novels,  comic books,  a
	1981 TV series, a 1984 video game, and 2005 feature film. A prominent series in British popular culture, The Hitchhiker&#39;s Guide to the Galaxy  has
	become an international multi-media phenomenon; the novels are the most widely distributed, having been translated into more than 30 languages  by
	2005. In 2017, BBC Radio 4 announced a 40th-anniversary celebration with Dirk Maggs, one of the original producers, in charge. This  sixth  series
	of the sci-fi spoof has been based on Eoin Colfer&#39;s book And Another Thing, with additional unpublished material by Douglas Adams.  The  first  of
	six new episodes was broadcast on 8 March 2018. The broad narrative of Hitchhiker follows the misadventures of  the  last  surviving  man,  Arthur
	Dent, following the demolition of the planet Earth by a Vogon constructor fleet to make way for a hyperspace bypass. Dent is rescued from  Earth&#39;s
	destruction by Ford Prefect, a human-like  alien  writer  for  the  eccentric,  electronic travel guide  The Hitchhiker&#39;s Guide to the Galaxy,  by
	hitchhiking onto a passing Vogon spacecraft. Following his rescue, Dent explores the galaxy with Prefect and encounters  Trillian,  another  human
	that had been taken from Earth prior to its destruction by the  President of the Galaxy,  the  two-headed  Zaphod Beeblebrox,  and  the  depressed
	Marvin, the Paranoid Android. Certain narrative details were changed between the various adaptations.

	Plot: The various versions follow the same basic plot but they are in many places mutually contradictory, as Adams rewrote the story substantially
	for each new adaptation. Throughout all versions, the  series  follows  the  adventures  of  Arthur Dent,  a  hapless  Englishman,  following  the
	destruction of the Earth by the Vogons, a race of unpleasant and bureaucratic aliens, to make way for an intergalactic bypass.  Dent&#39;s  adventures
	intersect with several other characters: Ford Prefect (who named himself after the Ford Prefect car to blend in with what was assumed  to  be  the
	dominant life form, automobiles), an alien from a small planet somewhere in the  vicinity  of  Betelgeuse  and  a  researcher  for  the  eponymous
	guidebook, who rescues Dent from Earth&#39;s destruction; Zaphod Beeblebrox, Ford&#39;s eccentric semi-cousin and the  Galactic President;  the  depressed
	robot Marvin the Paranoid Android; and Trillian, formerly known as Tricia McMillan, a woman Arthur once met at a party in Islington and  the  only
	other human survivor of Earth&#39;s destruction thanks to Beeblebrox&#39; intervention.

	Background: The first radio series comes from a proposal called "The Ends of the Earth": six self-contained  episodes,  all  ending  with  Earth&#39;s
	being destroyed in a different way. While writing the first episode, Adams realized that he needed someone on the  planet  who  was  an  alien  to
	provide some context, and that this alien needed a reason to be there. Adams finally settled on  making  the  alien  a  roving  researcher  for  a
	"wholly remarkable book" named The Hitchhiker&#39;s Guide to the Galaxy. As the first radio episode&#39;s writing progressed, the Guide became the  centre
	of his story, and he decided to focus the series on it, with the destruction of Earth being the only hold-over. Adams claimed that the title  came
	from a 1971 incident while he was hitchhiking around Europe as a young man with a copy of  the  Hitch-hiker&#39;s Guide to Europe  book:  while  lying
	drunk in a field near Innsbruck with a copy of the book and looking up at the stars, he thought it would be a good idea for  someone  to  write  a
	hitchhiker&#39;s guide to the galaxy as well. However, he later claimed that he had told this story so many times that he had forgotten  the  incident
	itself, and only remembered himself telling the story. His friends are quoted as saying that Adams mentioned the idea of "hitch-hiking around  the
	galaxy" to them while on holiday in Greece in 1973. Adams&#39;s fictional Guide  is  an  electronic  guidebook  to  the  entire  universe,  originally
	published by Megadodo Publications, one of the great publishing houses of Ursa Minor Beta. The narrative of the various versions of the story  are
	frequently punctuated with excerpts from the Guide. The voice of the Guide (Peter Jones in the first two  radio  series  and  TV  versions,  later
	William Franklyn in the third, fourth and  fifth  radio  series,  and  Stephen Fry  in  the  movie  version),  also  provides  general  narration.

	Original radio series: The first radio series of six episodes (called "Fits" after the names of the sections of Lewis Carroll&#39;s nonsense poem "The
	Hunting of the Snark") was broadcast in 1978 on BBC Radio 4. Despite a low-key launch of the series (the first episode was broadcast  at  10:30 pm
	on Wednesday, 8 March 1978), it received generally good reviews and a tremendous audience reaction for radio.  A  one-off  episode  (a  "Christmas
	special") was broadcast later in the year. The BBC had a practice at the time of commissioning  "Christmas Special"  episodes  for  popular  radio
	series, and while an early draft of this episode of The Hitchhiker&#39;s Guide had a Christmas-related plotline, it was  decided  to  be  "in slightly
	poor taste" and the episode as transmitted served as a bridge between the two series. This episode was released as part of the second radio series
	and, later, The Secondary Phase on cassettes and CDs. The Primary and Secondary Phases were aired, in a slightly edited  version,  in  the  United
	States on NPR Playhouse. The first series was repeated twice in 1978 alone and many more  times  in  the  next  few  years.  This  led  to  an  LP
	re-recording, produced independently of the BBC for sale, and a further adaptation of the series as a book. A second radio series, which consisted
	of a further six episodes, and bringing the total number of episodes to 12, was broadcast in 1980. The radio  series  (and the LP and TV versions)
	greatly benefited from the narration of noted comedy actor Peter Jones as The Book. He was cast after it was decided that a "Peter Jonesy" sort of
	voice was required. This led to a three-month search for an actor who sounded exactly like Peter Jones, which was unsuccessful. The producers then
	hired Peter Jones as exactly the "Peter Jonesy" voice they were looking for. The series was also notable for its use of  sound,  being  the  first
	comedy series to be produced in stereo. Adams said that he wanted the programme&#39;s production to be comparable to that of a modern rock album. Much
	of the programme&#39;s budget was spent on sound effects, which were largely the work of Paddy Kingsland (for  the  pilot  episode  and  the  complete
	second series) at the BBC Radiophonic Workshop and Dick Mills and Harry Parker (for the remaining  episodes (2–6) of the first series).  The  fact
	that they were at the forefront of modern radio production in 1978 and 1980 was reflected when the three new series of Hitchhiker&#39;s became some of
	the first radio shows to be mixed into four-channel Dolby Surround. This mix was also featured on DVD releases of  the  third  radio  series.  The
	theme tune used for the radio, television, LP and film versions is "Journey of the Sorcerer", an instrumental piece composed by Bernie Leadon  and
	recorded by The Eagles on their album One of These Nights. Only the transmitted radio series used the original recording; a sound-alike  cover  by
	Tim Souster was used for the LP and TV series, another arrangement by Joby Talbot was used for the 2005 film, and still another arrangement,  this
	time by Philip Pope, was recorded to be released with the CDs of the  last  three  radio  series.  Apparently,  Adams  chose  this  song  for  its
	futuristic-sounding nature, but also for the fact that it had a banjo in it, which, as Geoffrey Perkins recalls, Adams said would give an  "on the
	road, hitch-hiking feel" to it. The twelve episodes were released (in a slightly edited form, removing the Pink Floyd music and  two  other  tunes
	"hummed" by Marvin when the team land on Magrathea) on CD and cassette in 1988, becoming the first CD release in  the  BBC Radio Collection.  They
	were re-released in 1992, and at this time Adams suggested that they could retitle Fits the First to Sixth  as  "The Primary Phase"  and  Fits the
	Seventh to Twelfth as "The Secondary Phase" instead of just "the first series" and "the second series". It was at about this time that a "Tertiary
	Phase" was first discussed with Dirk Maggs, adapting Life, the Universe and Everything, but this series would not  be  recorded  for  another  ten
	years. Main cast:
						Simon Jones as Arthur Dent
						Geoffrey McGivern as Ford Prefect
						Susan Sheridan as Trillian
						Mark Wing-Davey as Zaphod Beeblebrox
						Stephen Moore as Marvin, the Paranoid Android
						Richard Vernon as Slartibartfast
						Peter Jones as The Book

	Novels: The novels are described as "a trilogy in five parts", having been described as a trilogy on the release of the  third book,  and  then  a
	"trilogy in four parts" on the release of the fourth book. The US edition of the fifth book was originally released  with  the  legend  "The fifth
	book in the increasingly inaccurately named Hitchhiker&#39;s Trilogy" on the cover. Subsequent re-releases of the other novels bore  the  legend  "The
	[first, second, third, fourth] book in the increasingly inaccurately named Hitchhiker&#39;s Trilogy".  In  addition,  the  blurb  on  the  fifth  book
	describes it as "the book that gives a whole new meaning to the word &#39;trilogy&#39;". The plots of the television and radio series are more or less the
	same as that of the first two novels, though some of the events occur in a different order and many of the details are changed. Much of parts five
	and six of the radio series were written by John Lloyd, but his material did not make it into the other versions of the story and is not  included
	here. Many consider the books&#39; version of events to be definitive because they are the most readily accessible and widely distributed  version  of
	the story. However, they are not the final version that Adams produced. Before his death from a heart attack on 11 May 2001, Adams was considering
	writing a sixth novel in the Hitchhiker&#39;s series. He was working on a third Dirk Gently novel, under the  working  title  The Salmon of Doubt, but
	felt that the book was not working and abandoned it. In an interview, he said some of the ideas in the book might fit better  in  the Hitchhiker&#39;s
	series, and suggested he might rework those ideas into a sixth book in that series. He described Mostly Harmless as "a very bleak book"  and  said
	he "would love to finish Hitchhiker on a slightly more upbeat note". Adams also remarked that if he were to write a sixth instalment, he would  at
	least start with all the characters in the same place. Eoin Colfer, who wrote the sixth book in the Hitchhiker&#39;s  series  in  2008–09,  used  this
	latter concept but none of the plot ideas from The Salmon of Doubt.
	
	The Hitchhiker&#39;s Guide to the Galaxy: In The Hitchhiker&#39;s Guide to the Galaxy (published in 1979),  the  characters  visit  the  legendary  planet
	Magrathea, home to the now-collapsed planet-building industry, and meet Slartibartfast, a planetary coastline designer who was responsible for the
	fjords of Norway. Through archival recordings, he relates the story of a race of hyper-intelligent pan-dimensional beings  who  built  a  computer
	named Deep Thought to calculate the Answer to the Ultimate Question of Life, the Universe, and Everything. When the answer was revealed to be  42,
	Deep Thought explained that the answer was incomprehensible because the beings didn&#39;t know what they were asking.  It  went  on  to  predict  that
	another computer, more powerful than itself would be made and designed by it to calculate the question for  the  answer.  (Later  on,  referencing
	this, Adams would  create  the 42 Puzzle, a puzzle which could be approached in multiple ways, all yielding the answer 42.)  The  computer,  often
	mistaken for a planet (because of its size and use of biological components), was the Earth, and was  destroyed  by  Vogons  to  make  way  for  a
	hyperspatial express route five minutes before the conclusion of its 10-million-year  program.  Two  members  of  the  race  of  hyper-intelligent
	pan-dimensional beings who commissioned the Earth in the first place disguise themselves as Trillian&#39;s mice, and want to dissect Arthur&#39;s brain to
	help reconstruct the question, since he was part of the Earth&#39;s matrix moments before it was destroyed, and so he is likely to have  part  of  the
	question buried in his brain. Trillian is also human but had left Earth six months previously with Zaphod Beeblebrox, President of the Galaxy. The
	protagonists escape, setting the course for "The Restaurant at the End of the Universe". The mice, in Arthur&#39;s absence, create  a  phony  question
	since it is too troublesome for them to wait 10 million years again just to cash in on a lucrative deal. The book was adapted from the first  four
	radio episodes. It was first published in 1979, initially in paperback, by Pan Books, after BBC Publishing had turned down the offer of publishing
	a novelization, an action they would later regret. The book reached number one on the book charts in only its second week, and sold  over  250,000
	copies within three months of its release. A hardback edition was published by Harmony Books, a division of Random House in the  United States  in
	October 1980, and the 1981 US paperback edition was promoted by the give-away of 3,000 free copies in the magazine Rolling Stone to build word  of
	mouth. In 2005, Del Rey Books rereleased the Hitchhiker series with new covers for the release of the 2005 movie. To date, it  has  sold  over  14
	million copies. A photo-illustrated edition of the first novel appeared in 1994.
	
	The Restaurant at the End of the Universe: In The Restaurant at the End of the Universe (published in 1980), Zaphod is separated from  the  others
	and finds he is part of a conspiracy to uncover who really runs the Universe. Zaphod meets Zarniwoop, a conspirator and editor for The Guide,  who
	knows where to find the secret ruler. Zaphod becomes briefly reunited with the others for a trip to Milliways, the restaurant of the title. Zaphod
	and Ford decide to steal a ship from there, which turns out to be a stunt ship pre-programmed to plunge into a star as a special effect in a stage
	show. Unable to change course, the main characters get Marvin to run the teleporter they find in the ship, which is working other than  having  no
	automatic control (someone must remain behind to operate it), and Marvin seemingly sacrifices himself.  Zaphod  and  Trillian  discover  that  the
	Universe is in the safe hands of a simple man living on a remote planet in a wooden shack with his cat. Ford and Arthur, meanwhile, end  up  on  a
	spacecraft full of the outcasts of the Golgafrinchan civilization. The ship crashes on prehistoric Earth; Ford and Arthur  are  stranded,  and  it
	becomes clear that the inept Golgafrinchans are the ancestors of modern humans,  having  displaced  the  Earth&#39;s  indigenous  hominids.  This  has
	disrupted the Earth&#39;s programming so that when Ford and Arthur manage to extract the final readout from  Arthur&#39;s  subconscious  mind  by  pulling
	lettered tiles from a Scrabble set, it is "What do you get if you multiply six by nine?"  Arthur  then  comments,  "I&#39;ve  always  said  there  was
	something fundamentally wrong with the universe." The book was adapted from the remaining material in the radio  series—covering  from  the  fifth
	episode to the twelfth episode, although the ordering was greatly changed (in particular, the events of Fit the Sixth, with Ford and Arthur  being
	stranded on pre-historic Earth, end the book, and their rescue in Fit the Seventh is deleted), and most of the Brontitall  incident  was  omitted,
	instead of the Haggunenon sequence, co-written by John Loyd, the Disaster Area stunt ship was substituted—this having first been introduced in the
	LP version. Adams himself considered Restaurant to be his best novel of the five.
	
	Life, the Universe and Everything: In Life, the Universe and Everything  (published in 1982),  Ford  and  Arthur  travel  through  the  space-time
	continuum from prehistoric Earth to Lord&#39;s Cricket Ground. There they run into Slartibartfast, who enlists their aid in preventing  galactic  war.
	Long ago, the people of Krikkit attempted to wipe out all life in the Universe, but they were stopped and imprisoned on  their  home  planet;  now
	they are poised to escape. With the help of Marvin, Zaphod, and Trillian, our heroes prevent the destruction of life in the Universe and go  their
	separate ways. This was the first Hitchhiker&#39;s book originally written as a book and not adapted from radio. Its story was based  on  a  treatment
	Adams had written for a Doctor Who theatrical release, with the Doctor role being split between Slartibartfast (to begin with), and later Trillian
	and Arthur. In 2004 it was adapted for radio as the Tertiary Phase of the radio series.
	
	So Long, and Thanks for All  the  Fish: In So Long, and Thanks for All the Fish  (published  in  1984),  Arthur  returns  home  to  Earth,  rather
	surprisingly since it was destroyed when he left. He meets and falls in love  with  a  girl  named  Fenchurch,  and  discovers  this  Earth  is  a
	replacement provided by the dolphins in their Save the Humans campaign. Eventually, he rejoins Ford, who claims to have saved the Universe in  the
	meantime, to hitch-hike one last time and see God&#39;s Final Message to His Creation. Along the way, they are joined by Marvin, the Paranoid Android,
	who, although 37 times older than the universe itself (what with time travel and all), has just enough power left in his failing body to read  the
	message and feel better about it all before expiring. This was the first Hitchhiker&#39;s novel which was not an adaptation of any previously  written
	story or script. In 2005 it was adapted for radio as the Quandary Phase of the radio series.

	Mostly Harmless: Finally, in Mostly Harmless  (published  in  1992),  Vogons  take  over  The Hitchhiker&#39;s Guide  (under  the  name  of  InfiniDim
	Enterprises), to finish, once and for all, the task of obliterating the Earth. After abruptly losing Fenchurch and  traveling  around  the  galaxy
	despondently, Arthur&#39;s spaceship crashes on the planet Lamuella, where he settles in happily as the official sandwich-maker for a small village of
	simple, peaceful people. Meanwhile, Ford Prefect breaks into The Guide&#39;s offices, gets himself an  infinite  expense  account  from  the  computer
	system, and then meets The Hitchhiker&#39;s Guide to the Galaxy, Mark II, an artificially intelligent, multi-dimensional guide with vast  power  and a
	hidden purpose. After he declines this dangerously powerful machine&#39;s aid (which he receives anyway), he sends it to Arthur Dent for  safety  ("Oh
	yes, whose?"—Arthur). Trillian uses DNA that Arthur donated for traveling money to have a daughter, and when she goes to cover a war,  she  leaves
	her daughter Random Frequent Flyer Dent with Arthur. Random, a more than typically troubled teenager, steals The Guide Mark II and uses it to  get
	to Earth. Arthur, Ford, Trillian, and Tricia McMillan (Trillian in this alternate universe) follow her to  a  crowded  club,  where  an  anguished
	Random becomes startled by a noise and inadvertently fires her gun at Arthur. The shot  misses  Arthur  and  kills  a  man  (the  ever-unfortunate
	Agrajag). Immediately afterwards, The Guide Mark II causes the removal of all possible Earths from probability. All of the main  characters,  save
	Zaphod, were on Earth at the time and are apparently killed, bringing a good deal of satisfaction to the Vogons. In 2005 it was adapted for  radio
	as the Quintessential Phase of the radio series, with the final episode first transmitted on 21 June 2005.
	
	And Another Thing...: It was announced in September 2008 that Eoin Colfer, author of Artemis Fowl,  had  been  commissioned  to  write  the  sixth
	instalment entitled And Another Thing... with the support of Jane Belson, Adams&#39;s widow. The book was published by Penguin Books  in  the  UK  and
	Hyperion in the US in October 2009. The story begins as death rays bear down on Earth, and the characters awaken from a  virtual  reality.  Zaphod
	picks them up shortly before they are killed, but completely fails to escape the death beams. They  are  then  saved  by  Bowerick Wowbagger,  the
	Infinitely Prolonged, whom they agree to help kill. Zaphod travels to Asgard to get Thor&#39;s help. In  the  meantime,  the  Vogons  are  heading  to
	destroy a colony of people who also escaped Earth&#39;s destruction, on the planet Nano. Arthur, Wowbagger, Trillian and Random head to Nano to try to
	stop the Vogons, and on the journey, Wowbagger and Trillian fall in love, making Wowbagger  question  whether  or  not  he  wants  to  be  killed.
	Zaphod arrives with Thor, who then signs up to be the planet&#39;s God. With Random&#39;s help, Thor almost kills Wowbagger. Wowbagger, who  merely  loses
	his immortality, then marries Trillian. Thor then stops the first Vogon attack and apparently dies. Meanwhile, Constant Mown,  son  of  Prostetnic
	Jeltz, convinces his father that the people on the planet are not citizens of Earth, but are, in fact, citizens of Nano, which means that it would
	be illegal to kill them. As the book draws to a close, Arthur is on his way to check  out  a  possible  university  for  Random,  when,  during  a
	hyperspace jump, he is flung across alternate universes, has a brief encounter with Fenchurch, and ends up exactly where  he  would  want  to  be.
	And then the Vogons turn up again. In 2017 it was adapted for radio as the Hexagonal Phase of the radio series, with its  premiere  episode  first
	transmitted on 8 March 2018, (exactly forty years, to the day, from the first episode of the first series, the Primary Phase).

	Omnibus editions: Two omnibus editions were created by Douglas Adams to combine the Hitchhiker series novels and to "set the record straight". The
	stories came in so many different formats that Adams stated that every time he told it he would contradict himself. Therefore, he  stated  in  the
	introduction of The More Than Complete Hitchhiker&#39;s Guide that  "anything I put down wrong here is, as far as I&#39;m concerned, wrong for good."  The
	two omnibus editions were  The More Than Complete Hitchhiker&#39;s Guide, Complete and Unabridged  (published in 1987)  and  The Ultimate Hitchhiker&#39;s
	Guide, Complete and Unabridged (published in 1997).
	The More Than Complete Hitchhiker&#39;s Guide: Published in 1987, this 624-page leatherbound omnibus edition contains "wrong for good" versions of the
	four Hitchhiker series novels at the time, and also includes one short story:
		The Hitchhiker&#39;s Guide to the Galaxy
		The Restaurant at the End of the Universe
		Life, the Universe and Everything
		So Long, and Thanks for All the Fish
		"Young Zaphod Plays it Safe"
	The Ultimate Hitchhiker&#39;s Guide: Published in 1997, this 832-page leatherbound final omnibus edition contains five Hitchhiker  series  novels  and
	one short story:
		The Hitchhiker&#39;s Guide to the Galaxy
		The Restaurant at the End of the Universe
		Life, the Universe and Everything
		So Long, and Thanks for All the Fish
		Mostly Harmless
		"Young Zaphod Plays it Safe"
	Also appearing in The Ultimate Hitchhiker&#39;s Guide, at the end of Adams&#39;s introduction, is a list  of  instructions  on  "How to Leave the Planet",
	providing a humorous explanation of how one might replicate Arthur and Ford&#39;s feat at the beginning of Hitchhiker&#39;s.

	Other Hitchhiker&#39;s-related books and stories:
		Related stories:
			A short story by Adams, "Young Zaphod Plays It Safe", first appeared in The Utterly Utterly Merry Comic Relief Christmas Book,  a  special
			large-print compilation of different stories and pictures that raised money for the then-new Comic Relief charity in  the  UK.  The  story
			also appears in some of the omnibus editions of the trilogy, and in The Salmon of Doubt. There are two 	versions of  this  story,  one  of
			which is slightly more explicit in its political commentary.

			A novel, Douglas Adams&#39; Starship Titanic: A Novel, written by Terry Jones, is based on Adams&#39;s computer game of  the  same  name,  Douglas
			Adams&#39;s Starship Titanic, which in turn is based on an idea from Life, the Universe and Everything. The idea concerns a  luxury  passenger
			starship that suffers "sudden and gratuitous total existence failure" on its maiden voyage.
			
			Wowbagger the Infinitely Prolonged, a character from Life, the Universe and Everything, also appears in a short story by Adams titled "The
			Private Life of Genghis Khan" which appears in some early editions of The Salmon of Doubt.

	Published radio scripts: Douglas Adams and Geoffrey Perkins collaborated on The Hitchhiker&#39;s Guide to the  Galaxy:  The  Original  Radio  Scripts,
	first published in the United Kingdom and United States in 1985. A tenth-anniversary (of the script book publication) edition was printed in 1995,
	and a twenty-fifth-anniversary (of the first radio series broadcast) edition was printed in 2003.  The 2004 series was produced by Above The Title
	Productions and the scripts were published in July 2005, with production notes for each episode. This second radio script  book  is  entitled  The
	Hitchhiker&#39;s Guide to the Galaxy Radio Scripts: The Tertiary, Quandary and Quintessential Phases. Douglas Adams gets the primary  writer&#39;s  credit
	(as he wrote the original novels), and there is a foreword by Simon Jones, introductions by the producer and the director, and other  introductory
	notes from other members of the cast.

	Television series: The popularity of the radio series gave rise to a six-episode television series,  directed  and  produced  by  Alan J. W. Bell,
	which first aired on BBC 2 in January and February 1981. It employed many of the actors from the radio series and was based mainly  on  the  radio
	versions of Fits the First to Sixth. A second series was at one point planned, with a storyline, according to Alan Bell and  Mark Wing-Davey  that
	would have come from Adams&#39;s abandoned Doctor Who and the Krikkitmen project (instead of simply making a TV version of the second  radio  series).
	However, Adams got into disputes with the BBC (accounts differ: problems with budget, scripts, and having Alan Bell involved are  all  offered  as
	causes), and the second series was never made. Elements of Doctor Who and the Krikkitmen were instead used in the  third novel, Life, the Universe
	and Everything. The main cast was the same as the original radio series, except for David Dixon as  Ford Prefect  instead  of McGivern, and Sandra
	Dickinson as Trillian instead of Sheridan.
	
	Other television appearances: Segments of several of the books were adapted as part of the BBC&#39;s The Big Read survey and programme,  broadcast  in
	late 2003. The film, directed by Deep Sehgal, starred Sanjeev Bhaskar as Arthur Dent, alongside Spencer Brown as Ford Prefect, Nigel Planer as the
	voice of Marvin, Stephen Hawking as the voice of Deep Thought, Patrick Moore as the voice of the Guide, Roger Lloyd-Pack  as  Slartibartfast,  and
	Adam Buxton and Joe Cornish as Loonquawl and Phouchg.

	Radio series three to five: On 21 June 2004, the BBC announced in a press release that a new series of Hitchhiker&#39;s based on the third novel would
	be broadcast as part of its autumn schedule, produced by Above the Title Productions Ltd. The episodes were recorded  in  late  2003,  but  actual
	transmission was delayed while an agreement was  reached  with  The  Walt  Disney  Company  over  Internet  re-broadcasts,  as  Disney  had  begun
	pre-production on the film. This was followed by news that further series would be produced based on the  fourth  and  fifth  novels.  These  were
	broadcast in September and October 2004 and May and June 2005. CD releases accompanied the transmission of the final episode in each  series.  The
	adaptation of the third novel followed the book very closely, which caused major structural issues in meshing with the preceding radio  series  in
	comparison to the second novel. Because many events from the radio series were omitted from the second novel, and those that did occur happened in
	a different order, the two series split in completely different directions. The last two adaptations vary somewhat—some events in Mostly  Harmless
	are now foreshadowed in the adaptation of So Long and Thanks For All The Fish,  while  both  include  some  additional  material  that  builds  on
	incidents in the third series to tie all five (and their divergent plotlines) together,  most  especially  including  the  character  Zaphod  more
	prominently in the final chapters and addressing his altered reality  to  include  the  events  of  the  Secondary Phase.  While  Mostly  Harmless
	originally contained a rather bleak ending, Dirk Maggs created a different ending for the transmitted radio version, ending  it  on  a  much  more
	upbeat note, reuniting the cast one last time. The core cast for the third to fifth radio series remained the same, except for the replacement  of
	Peter Jones by William Franklyn as the Book, and Richard Vernon by Richard Griffiths as Slartibartfast, since both had  died.  (Homage  to  Jones&#39;
	iconic portrayal of the Book was paid twice: the gradual shift of voices to a "new" version in episode 13, launching the new  productions,  and  a
	blend of Jones and Franklyn&#39;s voices at the end of the final episode, the first part of Maggs&#39; alternative ending.) Sandra Dickinson,  who  played
	Trillian in the TV series, here played Tricia McMillan, an English-born, American-accented alternate-universe version  of  Trillian,  while  David
	Dixon, the television series&#39; Ford Prefect, made a cameo appearance as the "Ecological Man". Jane Horrocks appeared in the new  semi-regular  role
	of Fenchurch, Arthur&#39;s girlfriend, and Samantha B&#233;art joined in the final series as Arthur and Trillian&#39;s daughter,  Random Dent.  Also  reprising
	their roles from the original radio series were Jonathan Pryce as Zarniwoop (here blended  with  a  character  from  the  final  novel  to  become
	Zarniwoop Vann Harl), Rula Lenska as Lintilla and her clones (and also as the  Voice  of  the  Bird),  and  Roy  Hudd  as  Milliways  compere  Max
	Quordlepleen, as well as the original radio series&#39; announcer, John Marsh. The series also featured guest appearances by such noted  personalities
	as Joanna Lumley as the Sydney Opera House Woman, Jackie Mason as the East River Creature, Miriam Margolyes as the  Smelly Photocopier Woman,  BBC
	Radio cricket legends Henry Blofeld and Fred Trueman as themselves, June Whitfield as the Raffle Woman,  Leslie Phillips as Hactar,  Saeed Jaffrey
	as the Man on the Pole, Sir Patrick Moore as himself, and Christian Slater as Wonko the Sane. Finally, Adams himself played the role of Agrajag, a
	performance adapted from his book-on-tape reading of the third novel, and edited into the series created  some  time  after  the  author&#39;s  death.

	Tertiary, Quandary and Quintessential Phase Main cast:
		Simon Jones as Arthur Dent
		Geoffrey McGivern as Ford Prefect
		Susan Sheridan as Trillian
		Mark Wing-Davey as Zaphod Beeblebrox
		Stephen Moore as Marvin, the Paranoid Android
		Richard Griffiths as Slartibartfast
		Sandra Dickinson as Tricia McMillan
		Jane Horrocks as Fenchurch
		Rula Lenska as the Voice of the Bird
		Samantha B&#233;art as Random
		William Franklyn as The Book
	
	Radio series six: The first of six episodes in a sixth series, the Hexagonal  Phase, was broadcast on  BBC Radio 4  on  8 March 2018 and  featured
	Professor Stephen Hawking  introducing  himself as the voice of The Hitchhiker’s Guide to the Galaxy Mk II  by  saying: "I have been quite popular
	in my time. Some even read my books."

	Film: After several years of setbacks and renewed efforts to start production and a quarter of a century after the first book  was  published, the
	big-screen adaptation of The Hitchhiker&#39;s Guide to the Galaxy was finally shot. Pre-production began in 2003, filming began on  19 April 2004  and
	post-production began in early September 2004. After a London premiere on 20 April 2005, it was released on 28 April in  the  UK and Australia, 29
	April in the United States and Canada, and 29 July in South Africa. (A full list of release dates is available  at  the  IMDb.)  The  movie  stars
	Martin Freeman as Arthur, Mos Def as Ford, Sam Rockwell as President of the  Galaxy Zaphod Beeblebrox and Zooey Deschanel as Trillian,  with  Alan
	Rickman providing the voice of Marvin the Paranoid Android (and Warwick Davis acting in Marvin&#39;s costume), and Stephen Fry as  the  voice  of  the
	Guide/Narrator. The plot of the film adaptation of Hitchhiker&#39;s Guide differs widely from that of the radio show, book and television  series. The
	romantic triangle between Arthur, Zaphod, and Trillian is more prominent in the film; and visits to Vogsphere, the homeworld of the Vogons (which,
	in the books, was already abandoned), and Viltvodle VI are inserted. The film covers roughly events in  the  first four radio episodes,  and  ends
	with the characters en route to the Restaurant at the End of the Universe, leaving the opportunity for a sequel open. A unique appearance is  made
	by the Point-of-View Gun, a device specifically created by Adams himself for the movie. Commercially the film was a  modest  success,  taking  $21
	million in its opening weekend in the United States, and nearly &#163;3.3 million in its opening weekend in the United Kingdom. The film  was  released
	on DVD (Region 2, PAL) in the UK on 5 September 2005. Both a standard double-disc edition and a UK-exclusive numbered  limited edition  "Giftpack"
	were released on this date. The "Giftpack" edition includes a copy of the novel with a "movie tie-in" cover, and collectible prints from the film,
	packaged in a replica of the film&#39;s version of the Hitchhiker&#39;s Guide prop. A single-disc widescreen or full-screen edition (Region 1, NTSC)  were
	made available in the United States and Canada on 13 September 2005. Single-disc releases in the Blu-ray format and UMD format for the PlayStation
	Portable were also released on the respective dates in these three countries.
	
	Stage shows: There have been multiple professional and amateur stage adaptations of The Hitchhiker&#39;s Guide to the Galaxy. There were  three  early
	professional productions, which were staged in 1979 and 1980. The first of these was performed  at  the  Institute of Contemporary Arts in London,
	between 1 and 19 May 1979, starring Chris Langham as Arthur Dent (Langham later returned to Hitchhiker&#39;s as Prak in the final  episode  of  2004&#39;s
	Tertiary Phase) and Richard Hope as Ford Prefect. This show was adapted from the first series&#39; scripts and was directed by Ken Campbell, who  went
	on to perform a character in the final episode of the second radio series. The show ran 90 minutes, but had an audience limited to  eighty  people
	per night. Actors performed on a variety of ledges and platforms, and the audience was pushed around in a hovercar, 1/2000th of an inch above  the
	floor. This was the first time that Zaphod was represented by having two actors in one large  costume.  The  narration  of  "The Book"  was  split
	between two usherettes, an adaptation that has appeared in no other version of H2G2. One of  these  usherettes,  Cindy Oswin,  went  on  to  voice
	Trillian for the LP adaptation. The second stage show was  performed  throughout  Wales  between  15 January  and  23 February 1980.  This  was  a
	production of Clwyd Theatr Cymru, and was directed by Jonathan Petherbridge. The company performed adaptations  of  complete  radio  episodes,  at
	times doing two episodes in a night, and at other times doing all six episodes of the first series in single three-hour sessions. This  adaptation
	was performed again at the Oxford Playhouse in December 1981, the Bristol Hippodrome, Plymouth&#39;s Theatre Royal in May–June 1982, and also  at  the
	Belgrade Theatre, Coventry, in July 1983. The third and least successful stage show was held at the Rainbow Theatre in London, in July 1980.  This
	was the second production directed by Ken Campbell. The Rainbow Theatre had been adapted for stagings of  rock  operas  in  the  1970s,  and  both
	reference books mentioned in footnotes indicate that this, coupled with incidental music throughout the  performance,  caused  some  reviewers  to
	label it as a "musical". This was the first adaptation for which Adams wrote the "Dish of the Day" sequence. The production  ran  for  over  three
	hours, and was widely panned for this, as well as for the music, laser effects, and the acting. Despite attempts to shorten the script,  and  make
	other changes, it closed three or four weeks early (accounts differ), and lost a lot of money. Despite the bad reviews, there were  at  least  two
	stand-out performances: Michael Cule and David Learner both went on from this production to appearances in the  TV adaptation. In  December 2011 a
	new stage production was announced to begin touring in June 2012. This included members of the original radio and TV casts  such  as  Simon Jones,
	Geoff McGivern, Susan Sheridan, Mark Wing-Davey and Stephen Moore with VIP guests playing the role of the Book. It was produced in the form  of  a
	radio show which could be downloaded when the tour was completed. This production was based on the first four Fits in  the  first  act,  with  the
	second act covering material from the rest of the series. The show also featured a band, who performed the songs  "Share and Enjoy",  the  Krikkit
	song "Under the Ink Black Sky", Marvin&#39;s song "How I Hate The Night", and "Marvin", which was a minor hit  in  1981.  The  production  featured  a
	series of "VIP guests" as the voice of  The Book  including  Billy Boyd,  Phill Jupitus,  Rory McGrath,  Roger McGough,  Jon Culshaw,  Christopher
	Timothy, Andrew Sachs, John Challis, Hugh Dennis, John Lloyd, Terry Jones and Neil Gaiman. The tour started on 8 June 2012 at  the  Theatre Royal,
	Glasgow and continued through the summer until 21 July when the final performance was at  Playhouse Theatre,  Edinburgh.  The  production  started
	touring again in September 2013, but the remaining dates of the tour were cancelled due to poor ticket sales.
	
	Live radio adaptation: On Saturday 29 March 2014, Radio 4 broadcast an adaptation in front of a live  audience,  featuring  many  members  of  the
	original cast including Stephen Moore, Susan Sheridan,  Mark Wing-Davey,  Simon Jones  and  Geoff McGivern,  with  John Lloyd  as  the  book.  The
	adaptation was adapted by Dirk Maggs primarily from Fit the First, including material from the books and later radio Fits  as  well  as  some  new
	jokes. It formed part of Radio 4&#39;s Character Invasion series. 
	
	LP album adaptations: The first four radio episodes were adapted for a new double LP, also entitled The Hitchhiker&#39;s Guide to the Galaxy (appended
	with "Part One" for the subsequent Canadian release), first by mail-order only, and  later  into  stores.  The  double  LP  and  its  sequel  were
	originally released by Original Records in the United Kingdom in 1979 and 1980, with the catalogue numbers ORA042  and  ORA054  respectively. They
	were first released by Hannibal Records in 1982 (as HNBL 2301 and HNBL 1307, respectively) in the United States and Canada, and later  re-released
	in a slightly abridged edition by Simon & Schuster&#39;s Audioworks in the mid-1980s. Both  were  produced  by  Geoffrey Perkins  and  featured  cover
	artwork by Hipgnosis. The script in the first double LP very closely follows the first four radio episodes, although further cuts had to  be  made
	for reasons of timing. Despite this, other lines of dialogue that were indicated as having been cut when  the  original  scripts  from  the  radio
	series were eventually published can be  heard  in  the  LP  version.  The  Simon & Schuster  cassettes  omit  the  Veet Voojagig  narration,  the
	cheerleader&#39;s speech as Deep Thought concludes its seven-and-one-half-million-year programme, and a few other lines from both sides of the  second
	LP of the set. Most of the original cast returned, except for Susan Sheridan, who was recording a voice for the character of  Princess Eilonwy  in
	The Black Cauldron for Walt Disney Pictures. Cindy Oswin voiced Trillian on all three LPs in her place. Other casting changes in the  first double
	LP included Stephen Moore taking on the additional role of the barman, and Valentine Dyall as the voice of  Deep Thought.  Adams&#39;s  voice  can  be
	heard making the public address announcements on Magrathea. Because of copyright issues, the music used during the first radio series  was  either
	replaced, or in the case of the title it was re-recorded in a  new  arrangement.  Composer  Tim Souster  did  both  duties  (with  Paddy Kingsland
	contributing music as well), and Souster&#39;s version of the theme was the version also used for the eventual television series.  The  sequel LP  was
	released, singly, as The Hitchhiker&#39;s Guide to the Galaxy Part Two: The Restaurant at the End of the  Universe  in  the  UK,  and  simply  as  The
	Restaurant at the End of the Universe in the USA. The script here mostly follows Fit the Fifth and Fit the Sixth,  but  includes  a  song  by  the
	backup band in the restaurant ("Reg Nullify and his Cataclysmic Combo"), and changes the Haggunenon sequence to "Disaster Area". As the result  of
	a misunderstanding, the second record was released before being cut down in a final edit that Douglas Adams and Geoffrey Perkins had both intended
	to make. Perkins has said, "[I]t is far too long on each side. It&#39;s  just  a  rough cut. [...] I felt it was flabby, and I wanted to speed it up."
	The Simon & Schuster Audioworks re-release of this LP was also abridged slightly from its  original  release.  The  scene  with  Ford Prefect  and
	Hotblack Desiato&#39;s bodyguard is omitted. Sales for the first double-LP release were primarily through mail order. Total sales reached over  60,000
	units, with half of those being mail order, and the other half through retail outlets. This  is  in  spite  of  the  facts  that Original Records&#39;
	warehouse ordered and stocked more copies than they were actually selling for quite some time, and that Paul Neil Milne Johnstone complained about
	his name and then-current address being included in the recording. This was corrected for a later pressing of the double-LP by "cut[ting] up  that
	part of the master tape and reassembl[ing] it in the wrong order". The second LP release ("Part Two") also only sold a total of  60,000  units  in
	the UK. The distribution deals for the United States and Canada with Hannibal Records and Simon and Schuster  were  later  negotiated  by  Douglas
	Adams and his agent, Ed Victor, after gaining full rights to the recordings from Original Records, which went bankrupt.

	Audiobook adaptations: There have been three audiobook recordings of the novel. The first was an abridged edition  (ISBN 0-671-62964-6),  recorded
	in the mid-1980s for the EMI label Music For Pleasure by Stephen Moore, best known for playing the voice  of  Marvin the Paranoid Android  in  the
	radio series and in the TV series. In 1990,  Adams  himself  recorded  an  unabridged  edition  for  Dove Audiobooks  (ISBN 1-55800-273-1),  later
	re-released by New Millennium Audio (ISBN 1-59007-257-X)  in  the  United States  and available from BBC Audiobooks in the United Kingdom. Also by
	arrangement with Dove, ISIS Publishing Ltd produced a numbered exclusive edition signed by Douglas Adams (ISBN 1-85695-028-X) in 1994.  To  tie-in
	with the 2005 film, actor Stephen Fry, the film&#39;s voice of the Guide, recorded a second  unabridged  edition  (ISBN 0-7393-2220-6).  In  addition,
	unabridged versions of books 2-5 of the  series were recorded by Martin Freeman for Random House Audio. Freeman plays  Arthur  in  the  2005  film
	adaptation. Audiobooks 2-5 follow in order  and  include: The Restaurant at the End of the Universe (ISBN 9780739332085);  Life, the Universe, and
	Everything (ISBN 9780739332108); So Long, and Thanks for All the Fish (ISBN 9780739332122); and Mostly Harmless (ISBN 9780739332146).

	Interactive fiction and video games: Sometime between 1982 and 1984  (accounts differ), the  British  company  Supersoft  published  a  text-based
	adventure game based on the book, which was released in versions for the Commodore PET and Commodore 64. One  account  states  that  there  was  a
	dispute as to whether valid permission for publication had been granted, and following legal action the  game  was  withdrawn  and  all  remaining
	copies were destroyed. Another account states that the programmer, Bob Chappell, rewrote the game  to  remove  all  Hitchhiker&#39;s  references,  and
	republished it as "Cosmic Capers". Officially, the TV series was followed in 1984 by a best-selling "interactive fiction", or text-based adventure
	game, distributed by Infocom. It was designed by Adams and Infocom regular Steve Meretzky and was one of Infocom&#39;s most successful games. As  with
	many Infocom games, the box contained a number of "feelies" including a  "Don&#39;t panic" badge,  some  "pocket fluff",  a  pair  of  peril-sensitive
	sunglasses (made of cardboard), an order for the destruction of the Earth, a small, clear plastic bag containing "a microscopic battle fleet"  and
	an order for the destruction of Arthur Dent&#39;s house  (signed by Adams and Meretzky).  In  September 2004,  it  was  revived  by  the  BBC  on  the
	Hitchhiker&#39;s section of the Radio 4 website for the initial broadcast of the Tertiary Phase, and is still  available  to  play  online.  This  new
	version uses an original Infocom datafile with a custom-written interpreter, by Sean Soll&#233;, and Flash programming by Shimon Young,  both  of  whom
	used to work at The Digital Village (TDV). The new version includes illustrations by Rod Lord, who was head of Pearce Animation Studios  in  1980,
	which produced the guide graphics for the TV series. On 2 March 2005 it won the Interactive BAFTA in the "best online entertainment"  category.  A
	sequel to the original Infocom game was never made. An all-new, fully graphical game was designed and developed by a  joint  venture  between  The
	Digital Village and PAN Interactive (no connection to Pan Books / Pan Mcmillan). This new game was planned and  developed  between  1998 and 2002,
	but like the sequel to the Infocom game, it also never materialised. In April 2005, Starwave Mobile released two mobile  games  to  accompany  the
	release of the film adaptation. The first, developed by Atatio, was called "The Hitchhiker&#39;s Guide to the Galaxy: Vogon Planet Destructor". It was
	a typical top-down shooter and except for the title had little to do with the actual story. The second game,  developed  by  TKO Software,  was  a
	graphical adventure game named "The Hitchhiker&#39;s Guide to the Galaxy: Adventure Game". Despite  its  name,  the  newly  designed  puzzles  by  TKO
	Software&#39;s Ireland studio were different from the Infocom ones, and the game followed the movie&#39;s script closely and included the  new  characters
	and places. The "Adventure Game" won the IGN&#39;s "Editors&#39; Choice Award" in May 2005. On 25 May 2011, Hothead Games announced they were working on a
	new edition of The Guide. Along with the announcement, Hothead Games launched a teaser web site made to look like an  announcement  from  Megadodo
	Publications that The Guide will soon be available on Earth. It has since been revealed that they are developing an iOS app in the  style  of  the
	fictional Guide.
	
	Comic books: In 1993, DC Comics, in conjunction with Byron Preiss Visual Publications,  published  a  three-part  comic  book  adaptation  of  the
	novelisation of The Hitchhiker&#39;s Guide to the Galaxy. This was followed up with three-part adaptations  of  The  Restaurant  at  the  End  of  the
	Universe in 1994, and Life, the Universe and Everything in 1996. There was also a series of collectors&#39; cards with art from and  inspired  by  the
	comic adaptations of the first book, and a graphic novelisation (or "collected edition") combining the three individual  comic  books  from  1993,
	itself released in May 1997. Douglas Adams was deeply opposed to the use of American English spellings and idioms in  what  he  felt  was  a  very
	British story, and had to be talked into it by the American publishers, although he remained very unhappy with  the  compromise.  The  adaptations
	were scripted by John Carnell. Steve Leialoha provided the art for Hitchhiker&#39;s and the layouts for Restaurant. Shepherd Hendrix did the  finished
	art for Restaurant. Neil Vokes and John Nyberg did the finished artwork for Life, based on breakdowns by Paris Cullins  (Book 1)  and  Christopher
	Schenck (Books 2–3). The miniseries were edited by Howard Zimmerman and Ken Grobe.
	
	"Hitch-Hikeriana": Many merchandising and spin-off items (or "Hitch-Hikeriana") were produced in the early 1980s, including  towels  in  different
	colours, all bearing the Guide entry for towels. Later runs of towels include those made for promotions by Pan Books, Touchstone Pictures / Disney
	for the 2005 movie, and different towels made for ZZ9 Plural Z Alpha,  the official Hitchhiker&#39;s Appreciation  society.  Other  items  that  first
	appeared in the mid-1980s were T-shirts, including those made for Infocom (such as one bearing the legend "I got the Babel Fish" for  successfully
	completing one of that game&#39;s most difficult puzzles), and a Disaster Area tour T-shirt. Other official items have included  "Beeblebears"  (teddy
	bears with an extra head and arm, named after Hitchhiker&#39;s character Zaphod Beeblebrox, sold by the official Appreciation Society), an  assortment
	of pin-on buttons and a number of novelty singles. Many of the above items  are  displayed  throughout  the  2004  "25th  Anniversary  Illustrated
	Edition" of the novel, which used items from the personal collections of fans of the  series.  Stephen  Moore  recorded  two  novelty  singles  in
	character as Marvin, the Paranoid Android: "Marvin"/"Metal Man" and "Reasons To Be Miserable"/"Marvin I Love You". The last song has appeared on a
	Dr. Demento compilation. Another single featured the re-recorded "Journey of the Sorcerer" (arranged by Tim Souster) backed  with  "Reg Nullify In
	Concert" by Reg Nullify, and "Only the End of the World Again" by Disaster Area (including Douglas Adams on bass guitar). These  discs  have since
	become collector&#39;s items.  The 2005 movie also added quite a few collectibles, mostly through the National Entertainment Collectibles Association.
	These included three prop  replicas  of objects seen on the Vogon ship and homeworld (a mug, a pen and a stapler), sets of "action figures" with a
	height of either 3 or 6 inches (76 or 150 mm), a gun—based on a prop used by Marvin, the Paranoid Android, that shoots foam darts, a crystal cube,
	shot glasses, a ten-inch (254 mm) high version of  Marvin  with  eyes  that light up green, and "yarn doll" versions of Arthur Dent, Ford Prefect,
	Trillian, Marvin and Zaphod Beeblebrox. Also, various audio tracks were released to coincide with the movie, notably re-recordings of "Marvin" and
	"Reasons To Be Miserable", sung by Stephen Fry, along with some of the "Guide Entries",  newly  written  material read in-character by Fry. SpaceX
	CEO Elon Musk launched his Tesla Roadster into an elliptical heliocentric orbit as part of the initial test launch of  the  Falcon Heavy.  On  the
	car&#39;s dashboard, the phrase "Don&#39;t Panic!" appears, as a nod to the Hitchhiker&#39;s Guide.
	
	International phenomenon: Many science fiction fans and radio listeners outside the United Kingdom were first exposed to The Hitchhiker&#39;s Guide to
	the Galaxy in one of two ways: shortwave radio broadcasts of the original radio series, or by Douglas Adams being "Guest of Honour"  at  the  1979
	World Science Fiction Convention, Seacon, held in Brighton, England. It was there that the radio series was nominated for a Hugo Award (the  first
	radio series to receive a nomination) but lost to Superman. A convention exclusively for H2G2, Hitchercon I, was held  in  Glasgow,  Scotland,  in
	September 1980, the year that the official fan club, ZZ9 Plural Z Alpha, was organised. In the early 1980s, versions  of  H2G2 became available in
	the United States, Canada, Germany (Per Anhalter durch die Galaxis), Denmark (H&#229;ndbog for vakse galakseblaffere), the Netherlands (Transgalactisch
	Liftershandboek), Sweden (Liftarens guide till galaxen), Finland (Linnunradan K&#228;sikirja Liftareille) and also Israel (מדריך הטרמפיסט לגלקסיה).  In
	the meantime the book has been translated into more than thirty  languages,  such  as  Bulgarian  (Пътеводител на галактическия стопаджия),  Czech
	(Stopařův průvodce Galaxi&#237;), Farsi/Persian (راهنمای مسافران مجانی کهکشان), French (Le routard galactique), Greek (Γυρίστε το Γαλαξία με Ωτο-στόπ),
	Hungarian (Galaxis &#218;tikalauz stopposoknak), Italian (Guida galattica per gli autostoppisti),
	Japanese (銀河ヒッチハイク・ガイド), Korean (은하수를 여행하는히치하이커를 위한 안내서),
	Latvian  (Galaktikas   ceļvedis   stopētājiem),   Norwegian   (Haikerens   guide   til   Galaksen,   first   published   as  P&#229;  tommeltotten  til
	melkeveien), Brazilian Portuguese (Guia do Mochileiro das Gal&#225;xias), Portuguese (&#192; Boleia Pela  Gal&#225;xia),  Polish  (Autostopem  przez  galaktykę),
	Romanian (Ghidul autostopistului galactic), Russian (Автостопом по Галактике), Serbian (Autostoperski vodič kroz galaksiju), Slovenian  (Štoparski
	vodnik po Galaksiji), Spanish (Gu&#237;a del autoestopista gal&#225;ctico), Slovak (Stop&#225;rov sprievodca galaxiou), Czech  (Stopařův  průvodce  galaxi&#237;)  and
	Turkish (Otostop&#231;unun Galaksi Rehberi).
	
	Spelling: The different versions of the series spell the title  differently−thus  Hitch-Hiker&#39;s Guide,  Hitch Hiker&#39;s Guide and Hitchhiker&#39;s Guide
	are used in different editions (US or UK), formats (audio or print) and compilations of the book, with some omitting the apostrophe. Some editions
	used different spellings on the spine and title page.  The h2g2&#39;s English Usage in Approved Entries claims that Hitchhiker&#39;s Guide is the spelling
	Adams preferred. At least two reference works make note of the inconsistency in the titles. Both, however, repeat the statement that Adams decided
	in 2000 that "everyone should spell it the same way [one word, no hyphen] from then on."
	
	Bibliography:
		Adams, Douglas (2002).
		Guzzardi, Peter, ed. The Salmon of Doubt: Hitchhiking the Galaxy One Last Time (first UK ed.). Macmillan. ISBN 0-333-76657-1 (2003).
		Perkins, Geoffrey, ed. The Hitchhiker&#39;s Guide to the Galaxy: The Original Radio Scripts. MJ Simpson, add. mater (25th Anniversary ed.).
			Pan Books. ISBN 0-330-41957-9.
		Gaiman, Neil (2003). Don&#39;t Panic: Douglas Adams and the "Hitchhiker&#39;s Guide to the Galaxy". Titan Books. ISBN 1-84023-742-2.
		Simpson, M. J. (2003). Hitchhiker: A Biography of Douglas Adams (first US ed.). Justin Charles & Co. ISBN 1-932112-17-0.
		The Pocket Essential Hitchhiker&#39;s Guide (second ed.) (2005). Pocket Essentials. ISBN 1-904048-46-3.
		Stamp, Robbie, editor (2005). The Making of The Hitchhiker&#39;s Guide to the Galaxy: The Filming of the Douglas Adams Classic. Boxtree.
			ISBN 0-7522-2585-5.
		Webb, Nick (2005). Wish You Were Here: The Official Biography of Douglas Adams (first US hardcover ed.). Ballantine Books. ISBN 0-345-47650-6.

	The following text has been lifted from WikiPedia on 19 June 2018. To see the most recent version of this text, visit:
	https://en.wikipedia.org/wiki/The_Hitchhiker%27s_Guide_to_the_Galaxy_(novel)
	The Hitchhiker&#39;s Guide to the Galaxy is the first of five books in  the  Hitchhiker&#39;s Guide to the Galaxy  comedy  science  fiction  "trilogy"  by
	Douglas Adams. The novel is an adaptation of the first four parts of Adams&#39; radio series of the same  name.  The  novel  was  first  published  in
	London on 12 October 1979. It sold 250,000 copies in the first three months.  The  namesake  of  the  novel  is  The  Hitchhiker&#39;s  Guide  to  the
	Galaxy, a fictional guide book for hitchhikers (inspired  by the  Hitch-hiker&#39;s  Guide  to  Europe)  written  in  the  form  of  an  encyclopedia.
	Plot summary: The book begins with city council workmen arriving at  Arthur Dent&#39;s  house. They  wish  to  demolish  his house in order to build a
	bypass. Arthur&#39;s best friend, Ford Prefect, arrives, warning him of the end of the world. Ford is  revealed  to  be  an  alien  who  had  come  to
	Earth to research it for the titular Hitchhiker&#39;s Guide to the Galaxy, an enormous work providing  information  about  every  planet  and place in
	the universe. The two head to a pub, where the locals question Ford&#39;s knowledge of the Apocalypse. An alien race, known  as  Vogons,  show  up  to
	demolish Earth in order to build a bypass for an intergalactic highway. Arthur and Ford manage to get onto the Vogon ship  just  before  Earth  is
	demolished, where they are forced to listen to horrible Vogon poetry as a form of torture. Arthur and Ford  are  ordered  to  say  how  much  they
	like the poetry in order to avoid being thrown out of the airlock, and while Ford finds  listening  to  be  painful,  Arthur  believes  it  to  be
	genuinely good, since human poetry is apparently even worse. Arthur and Ford are then placed into the airlock  and  jettisoned  into  space,  only
	to  be  rescued  by  Zaphod Beeblebrox&#39;s  ship,  the Heart of Gold.  Zaphod, a  semi-cousin  of  Ford,  is  the  President of the Galaxy,  and  is
	accompanied by a depressed robot named Marvin and a human woman by the name of Trillian. The five embark  on  a  journey  to  find  the  legendary
	planet known as  Magrathea,  known  for  selling  luxury  planets.  Once  there,  they  are  taken  into  the  planet&#39;s  centre  by  a  man  named
	Slartibartfast. There,  they  learn  that  a  supercomputer  named  Deep Thought,  who  determined  the ultimate answer to life, the universe, and
	everything to be the number 42, created Earth as an even greater computer to calculate  the  question  to  which  42  is  the  answer.  Trillian&#39;s
	mice, actually part of the group of sentient and hyper-intelligent superbeings that  had  Earth  created  in  the  first place, reject the idea of
	building a second Earth to redo the process, and offer to  buy  Arthur&#39;s brain in the hope that it contains  the  question,  leading  to  a  fight
	when  he  declines.  Zaphod  saves  Arthur  when the brain is about to be removed, and the group decides to go to The Restaurant at the End of the
	Universe.
		
	Illustrated edition: The Illustrated Hitchhiker&#39;s Guide to the Galaxy is a specially designed book made in 1994.  It  was  first  printed  in  the
	United Kingdom by Weidenfeld & Nicolson and in  the  United States by Harmony Books  (who sold it for $42.00).  It  is an oversized book, and came
	in silver-foil "holographic" covers in both the  UK and US  markets.  It  features  the  first  appearance  of  the  42  Puzzle, designed by Adams
	himself, a photograph of Adams and his literary agent Ed Victor as  the  two  space  cops,  and  many  other  designs  by  Kevin Davies,  who  has
	participated in many Hitchhiker&#39;s related projects since the stage  productions  in  the  late  1970s.  Davies  himself  appears  as Prosser. This
	edition is out of print – Adams bought up many remainder copies and sold them, autographed, on his website.
		
	In other media:  Audiobook  adaptations:  There  have  been  three  audiobook  recordings  of  the  novel.  The  first  was  an  abridged  edition
	(ISBN 0-671-62964-6), recorded in the mid-1980s by Stephen Moore, best known for playing the voice  of  Marvin  the  Paranoid Android in the radio
	series, LP adaptations and in the TV series. In 1990, Adams himself recorded  an  unabridged  edition  for  Dove Audiobooks  (ISBN 1-55800-273-1),
	later re-released by New Millennium Audio (ISBN 1-59007-257-X)  in  the  United  States  and  available from BBC Audiobooks in the United Kingdom.
	Also by arrangement with Dove, ISIS Publishing Ltd produced a numbered exclusive edition signed by  Douglas Adams  (ISBN 1-85695-028-X)  in  1994.
	To tie-in with the 2005 film, actor Stephen Fry, the film&#39;s voice of  the  Guide,  recorded  a  second  unabridged  edition  (ISBN 0-7393-2220-6).

	Television series: The popularity of the radio series gave rise to a six-episode television series,  directed  and  produced  by  Alan J. W. Bell,
	which first aired on BBC 2 in January and February 1981. It employed many  of the  actors  from the radio series and was based mainly on the radio
	versions of Fits the First through Sixth. A second series was at one point  planned, with  a storyline, according to Alan Bell and Mark Wing-Davey
	that would have come from Adams&#39;s abandoned Doctor Who and the Krikkitmen project (instead of simply making  a  TV version  of  the  second  radio
	series). However, Adams got into disputes with the BBC (accounts differ: problems with budget, scripts, and  having  Alan Bell  involved  are  all
	offered as causes), and the second series was never made. Elements of Doctor Who and the Krikkitmen were instead used in  the  third  novel, Life,
	the Universe and Everything. The main cast was the same as the original radio series, except for David Dixon as Ford Prefect instead of  McGivern,
	and Sandra Dickinson as Trillian instead of Sheridan.
	
	Film adaptation: The Hitchhiker&#39;s Guide to the Galaxy was adapted into a science fiction comedy film directed by Garth Jennings  and  released  on
	28 April 2005 in the UK, Australia and New Zealand, and on the following day in the United States  and  Canada.  It  was  rolled  out  to  cinemas
	worldwide during May, June, July, August and September.
	
	Series: The deliberately misnamed Hitchhiker&#39;s Guide to the Galaxy "Trilogy" consists of six books, five written by  Adams: The Hitchhiker&#39;s Guide
	to the Galaxy (1979), The Restaurant at the End of the Universe (1980), Life, the Universe and Everything (1982),  So Long, and Thanks for All the
	Fish (1984) and Mostly Harmless (1992). On 16 September 2008 it was announced that Irish author Eoin Colfer was to pen a  sixth  book.  The  book,
	entitled And Another Thing...,  was  published  in   October  2009,   on  the   30th  anniversary  of  the  publication  of  the  original  novel.
	
	Legacy: When Elon Musk&#39;s Tesla Roadster was launched into space on the maiden flight of the Falcon Heavy rocket in February 2018, it had the words
	DON&#39;T PANIC on the dashboard display and carried amongst other items a copy of the novel and a towel.
	
	Awards:
		Number one on the Sunday Times best seller list (1979)
		Author received the "Golden Pan" (From his publishers for reaching the 1,000,000th book sold) (1984)
		Waterstone&#39;s Books/Channel Four&#39;s list of the &#39;One Hundred Greatest Books of the Century&#39;, at number 24. (1996)
		BBC&#39;s "Big Read", an attempt to find the "Nation&#39;s Best-loved book", ranked it number four. (2003)
		
*/

/*	========================================================================================	*/
contract ERC20Basic {uint256 public totalSupply; function balanceOf(address who) public constant returns (uint256); function transfer(address to, uint256 value) public returns (bool); event Transfer(address indexed from, address indexed to, uint256 value);}
/*	========================================================================================	*/ 
/* ERC20 interface see https://github.com/ethereum/EIPs/issues/20 */
contract ERC20 is ERC20Basic {function allowance(address owner, address spender) public constant returns (uint256); function transferFrom(address from, address to, uint256 value) public returns (bool); function approve(address spender, uint256 value) public returns (bool); event Approval(address indexed owner, address indexed spender, uint256 value);}
/*	========================================================================================	*/ 
/*  SafeMath - the lowest gas library - Math operations with safety checks that throw on error */
library SafeMath {function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a * b; assert(a == 0 || c / a == b); return c;}
// assert(b > 0); // Solidity automatically throws when dividing by 0
// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b; return c;}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a); return a - b;}
function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b; assert(c >= a); return c;}}
/*	========================================================================================	*/ 
/*	Basic token Basic version of StandardToken, with no allowances. */
contract BasicToken is ERC20Basic {using SafeMath for uint256; mapping(address => uint256) balances;
function transfer(address _to, uint256 _value) public returns (bool) {balances[msg.sender] = balances[msg.sender].sub(_value); balances[_to] = balances[_to].add(_value); Transfer(msg.sender, _to, _value); return true;}
/*	========================================================================================	*/ 
/* Gets the balance of the specified address.
   param _owner The address to query the the balance of. 
   return An uint256 representing the amount owned by the passed address.
*/
function balanceOf(address _owner) public constant returns (uint256 balance) {return balances[_owner];}}
/*	========================================================================================	*/ 
/*  Implementation of the basic standard token. https://github.com/ethereum/EIPs/issues/20 */
contract StandardToken is ERC20, BasicToken {mapping (address => mapping (address => uint256)) allowed;
/*  Transfer tokens from one address to another
    param _from address The address which you want to send tokens from
    param _to address The address which you want to transfer to
    param _value uint256 the amout of tokens to be transfered
*/
function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {var _allowance = allowed[_from][msg.sender];
// Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
// require (_value <= _allowance);
balances[_to] = balances[_to].add(_value); balances[_from] = balances[_from].sub(_value); allowed[_from][msg.sender] = _allowance.sub(_value); Transfer(_from, _to, _value); return true;}
/*  Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    param _spender The address which will spend the funds.
    param _value The amount of Douglas Adams&#39; tokens to be spent.
*/
function approve(address _spender, uint256 _value) public returns (bool) {
//  To change the approve amount you must first reduce the allowance
//  of the adddress to zero by calling `approve(_spender, 0)` if it
//  is not already 0 to mitigate the race condition described here:
//  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
require((_value == 0) || (allowed[msg.sender][_spender] == 0)); allowed[msg.sender][_spender] = _value; Approval(msg.sender, _spender, _value); return true;}
/*  Function to check the amount of tokens that an owner allowed to a spender.
    param _owner address The of the funds owner.
    param _spender address The address of the funds spender.
    return A uint256 Specify the amount of tokens still available to the spender.   */
function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {return allowed[_owner][_spender];}}
/*	========================================================================================	*/ 
/*  The Ownable contract has an owner address, and provides basic authorization control
    functions, this simplifies the implementation of "user permissions".    */
contract Ownable {address public owner;
/*  Throws if called by any account other than the owner.                   */
function Ownable() public {owner = msg.sender;} modifier onlyOwner() {require(msg.sender == owner);_;}
/*  Allows the current owner to transfer control of the contract to a newOwner.
    param newOwner The address to transfer ownership to.    */
function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0)); owner = newOwner;}}
/*	========================================================================================	*/
contract H2G2 is StandardToken, Ownable {
    string public constant name = "The Hitchhiker&#39;s Guide to the Galaxy";
        string public constant symbol = "H2G2";
            string public version = &#39;V1.0.42.000.000.The.Primary.Phase&#39;;
            uint public constant decimals = 18;
        uint256 public initialSupply;
    uint256 public unitsOneEthCanBuy;           /*  How many units of H2G2 can be bought by 1 ETH?  */
uint256 public totalEthInWei;                   /*  WEI is the smallest unit of ETH (the equivalent */
                                                /*  of cent in USD or satoshi in BTC). We&#39;ll store  */
                                                /*  the total ETH raised via the contract here.     */
address public fundsWallet;                     /*  Where should ETH sent to the contract go?       */
    function H2G2 () public {
        totalSupply = 42000000 * 10 ** decimals;
            balances[msg.sender] = totalSupply;
                initialSupply = totalSupply;
            Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, totalSupply);
    unitsOneEthCanBuy = 1000;                   /*  Set the contract price of the H2G2 token        */
fundsWallet = msg.sender;                       /*  The owner of the contract gets the ETH sent     */
                                                /*  to the H2G2 contract                            */
}function() public payable{totalEthInWei = totalEthInWei + msg.value; uint256 amount = msg.value * unitsOneEthCanBuy; require(balances[fundsWallet] >= amount); balances[fundsWallet] = balances[fundsWallet] - amount; balances[msg.sender] = balances[msg.sender] + amount;
Transfer(fundsWallet, msg.sender, amount);      /*  Broadcast a message to the blockchain           */
/*  Transfer ether to fundsWallet   */
fundsWallet.transfer(msg.value);}
/*  Approves and then calls the receiving contract */
function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {allowed[msg.sender][_spender] = _value; Approval(msg.sender, _spender, _value);
/*  call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
    receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
    it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.  */
if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { return; } return true;}}
/*	========================================================================================	*/
/*	At the risk of being quite redundant, we shall reiterate some of the previously provided information from the header section of this token  code.
	As mentioned above, this token has a total supply of 42,000,000 tokens which is not only twice the total supply of  BitCoin (BTC),  but  is  also
	shades of "The Ultimate Question of Life, the Universe and Everything" to which the answer is forty two. The supplementary token, however, has  a
	total supply of only 42 tokens, the reason for which should be quite obvious. The "ticker" symbol for these two tokens differ only by case:  This
	token is H2G2 whilst the supplementary token is h2g2. The token names however are completely different. This token  is  The Hitchhiker&#39;s Guide to
	the Galaxy whilst the supplemental token is HHGTTG. We  would  wish to ask that you refrain from using non-existent words: "hodl", abbreviations:
	"lambo", and ridiculous phrases: "to the moon" when referring to these tokens. We  would  much  prefer  the use of such terms as: "hold until the
	ends of the earth", "star buggy", and "to magrathea". Marvin the Paranoid Android thanks you in advance, for he has  waited  576 thousand million
	years for these tokens to rematerialize out of the space time continuum. Now, THAT my friends is HOLDING. Although we do not plan to offer  these
	tokens for sale, they may be acquired by simply sending eth to the contract address. The contract will then respond by sending tokens back to the
	address from which the eth was sent. The smallest amount of eth that may be sent to the  contract  is:  .000000000000000001.  The  contract  will
	exhibit this behaviour until such time as the total supply of tokens has been depleted.		*/
/*	========================================================================================	*/