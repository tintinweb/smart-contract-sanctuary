pragma solidity ^0.4.4;

	///
    /// This ERC20 Token HHGTTG (h2g2) is NOT meant to have any intrinsic (fundamental) value nor any
    /// monetary value whatsoever. It is designed to honour the memory of Douglas Noel Adams.
	/// 11 May 2001 would become one of the worst days of my life. My one true hero ceased to
	/// exist as did my hope of a further h2g2 (HG2G) novel, although Eoin Colfer would eventually
	/// pen "And Another Thing", it just wasn&#39;t the same. If your interest in this token is piqued,
	/// the you will no doubt know WHY the Total Supply is ONLY 42 Tokens. This Token Contract has been
	/// designed to return the SAME amount of HHGTTG (h2g2) Tokens as the amount of ETH sent to the
	/// contract with the smallest amount being: .000000000000000001 of ETH which will return the same
	/// amount of h2g2 until the total supply of 42 h2g2 Tokens is depleted. The following text has been
	/// lifted from WikiPedia on 8 June 2018, the date of creation of this token.
	/// https://en.wikipedia.org/wiki/Douglas_Adams
	/// Douglas Noel Adams (11 March 1952 – 11 May 2001) was an English author, scriptwriter,
	/// essayist, humorist, satirist and dramatist. Adams was author of The Hitchhiker&#39;s Guide
	/// to the Galaxy, which originated in 1978 as a BBC radio comedy before developing into a
	/// "trilogy" of five books that sold more than 15 million copies in his lifetime and generated
	/// a television series, several stage plays, comics, a computer game, and in 2005 a feature film.
	/// Adams&#39;s contribution to UK radio is commemorated in The Radio Academy&#39;s Hall of Fame. Adams
	/// also wrote Dirk Gently&#39;s Holistic Detective Agency (1987) and The Long Dark Tea-Time of the
	/// Soul (1988), and co-wrote The Meaning of Liff (1983), The Deeper Meaning of Liff (1990), Last
	/// Chance to See (1990), and three stories for the television series Doctor Who; he also served
	/// as script editor for the show&#39;s seventeenth season in 1979. A posthumous collection of his
	/// works, including an unfinished novel, was published as The Salmon of Doubt in 2002.
	///
	/// Adams was an advocate for environmentalism and conservation, a lover of fast cars,
	/// technological innovation and the Apple Macintosh, and a radical atheist.
	///
    /// Early life: Adams was born on 11 March 1952 to Janet (n&#233;e Donovan; 1927–2016) and
	/// Christopher Douglas Adams (1927–1985) in Cambridge, England.[3] The family moved to the East
	/// End of London a few months after his birth, where his sister, Susan, was born three years later.
	/// His parents divorced in 1957; Douglas, Susan, and their mother moved to an RSPCA animal shelter
	/// in Brentwood, Essex, run by his maternal grandparents.
	///
    /// Education: Adams attended Primrose Hill Primary School in Brentwood. At nine, he passed the
	/// entrance exam for Brentwood School, an independent school whose alumni include Robin Day,
	/// Jack Straw, Noel Edmonds, and David Irving. Griff Rhys Jones was a year below him, and he was in
	/// the same class as Stuckist artist Charles Thomson. He attended the prep school from 1959 to 1964,
	/// then the main school until December 1970. Adams was 6 feet (1.8 m) by age 12 and stopped growing
	/// at 6 feet 5 inches (1.96 m). His form master, Frank Halford, said his height had made him stand out
	/// and that he had been self-conscious about it. His ability to write stories made him well known in
	/// the school. He became the only student ever to be awarded a ten out of ten by Halford for creative
	/// writing, something he remembered for the rest of his life, particularly when facing writer&#39;s block.
	/// Some of his earliest writing was published at the school, such as a report on its photography club
	/// in The Brentwoodian in 1962, or spoof reviews in the school magazine Broadsheet, edited by Paul Neil
	/// Milne Johnstone, who later became a character in The Hitchhiker&#39;s Guide. He also designed the cover
	/// of one issue of the Broadsheet, and had a letter and short story published in The Eagle, the boys&#39;
	/// comic, in 1965. A poem entitled "A Dissertation on the task of writing a poem on a candle and an
	/// account of some of the difficulties thereto pertaining" written by Adams in January 1970, at the age
	/// of 17, was discovered in a cupboard at the school in early 2014. On the strength of a bravura essay
	/// on religious poetry that discussed the Beatles and William Blake, he was awarded an Exhibition in
	/// English at St John&#39;s College, Cambridge, going up in 1971. He wanted to join the Footlights, an
	/// invitation-only student comedy club that has acted as a hothouse for comic talent. He was not
	/// elected immediately as he had hoped, and started to write and perform in revues with Will Adams
	/// (no relation) and Martin Smith, forming a group called "Adams-Smith-Adams", but became a member of
	/// the Footlights by 1973. Despite doing very little work—he recalled having completed three essays in
	/// three years—he graduated in 1974 with a B.A. in English literature.
    /// 
    /// Career: Writing: After leaving university Adams moved back to London, determined to break into TV
	/// and radio as a writer. An edited version of the Footlights Revue appeared on BBC2 television in 1974.
	/// A version of the Revue performed live in London&#39;s West End led to Adams being discovered by Monty
	/// Python&#39;s Graham Chapman. The two formed a brief writing partnership, earning Adams a writing credit
	/// in episode 45 of Monty Python for a sketch called "Patient Abuse". The pair also co-wrote the
	/// "Marilyn Monroe" sketch which appeared on the soundtrack album of Monty Python and the Holy Grail.
	/// Adams is one of only two people other than the original Python members to get a writing credit (the
	/// other being Neil Innes). Adams had two brief appearances in the fourth series of Monty Python&#39;s Flying
	/// Circus. At the beginning of episode 42, "The Light Entertainment War", Adams is in a surgeon&#39;s mask (as
	/// Dr. Emile Koning, according to on-screen captions), pulling on gloves, while Michael Palin narrates a
	/// sketch that introduces one person after another but never gets started. At the beginning of episode 44,
	/// "Mr. Neutron", Adams is dressed in a pepper-pot outfit and loads a missile onto a cart driven by
	/// Terry Jones, who is calling for scrap metal ("Any old iron..."). The two episodes were broadcast in
	/// November 1974. Adams and Chapman also attempted non-Python projects, including Out of the Trees. At
	/// this point Adams&#39;s career stalled; his writing style was unsuited to the then-current style of radio
	/// and TV comedy. To make ends meet he took a series of odd jobs, including as a hospital porter, barn
	/// builder, and chicken shed cleaner. He was employed as a bodyguard by a Qatari family, who had made
	/// their fortune in oil. During this time Adams continued to write and submit sketches, though few were
	/// accepted. In 1976 his career had a brief improvement when he wrote and performed Unpleasantness at
	/// Brodie&#39;s Close at the Edinburgh Fringe festival. By Christmas, work had dried up again, and a
	/// depressed Adams moved to live with his mother. The lack of writing work hit him hard and low confidence
	/// became a feature of Adams&#39;s life; "I have terrible periods of lack of confidence [..] I briefly did
	/// therapy, but after a while I realised it was like a farmer complaining about the weather. You can&#39;t fix
	/// the weather – you just have to get on with it". Some of Adams&#39;s early radio work included sketches for
	/// The Burkiss Way in 1977 and The News Huddlines. He also wrote, again with Chapman, 20 February 1977
	/// episode of Doctor on the Go, a sequel to the Doctor in the House television comedy series. After the
	/// first radio series of The Hitchhiker&#39;s Guide became successful, Adams was made a BBC radio producer,
	/// working on Week Ending and a pantomime called Black Cinderella Two Goes East. He left after six months
	/// to become the script editor for Doctor Who. In 1979 Adams and John Lloyd wrote scripts for two half-hour
	/// episodes of Doctor Snuggles: "The Remarkable Fidgety River" and "The Great Disappearing Mystery"
	/// (episodes eight and twelve). John Lloyd was also co-author of two episodes from the original Hitchhiker
	/// radio series ("Fit the Fifth" and "Fit the Sixth", also known as "Episode Five" and "Episode Six"), as
	/// well as The Meaning of Liff and The Deeper Meaning of Liff.
	///
    /// The Hitchhiker&#39;s Guide to the Galaxy: The Hitchhiker&#39;s Guide to the Galaxy was a concept for a
	/// science-fiction comedy radio series pitched by Adams and radio producer Simon Brett to BBC Radio 4 in
	/// 1977. Adams came up with an outline for a pilot episode, as well as a few other stories (reprinted in
	/// Neil Gaiman&#39;s book Don&#39;t Panic: The Official Hitchhiker&#39;s Guide to the Galaxy Companion) that could be
	/// used in the series. According to Adams, the idea for the title occurred to him while he lay drunk in a
	/// field in Innsbruck, Austria, gazing at the stars. He was carrying a copy of the Hitch-hiker&#39;s Guide to
	/// Europe, and it occurred to him that "somebody ought to write a Hitchhiker&#39;s Guide to the Galaxy". He
	/// later said that the constant repetition of this anecdote had obliterated his memory of the actual event.
	/// Despite the original outline, Adams was said to make up the stories as he wrote. He turned to John Lloyd
	/// for help with the final two episodes of the first series. Lloyd contributed bits from an unpublished
	/// science fiction book of his own, called GiGax. Very little of Lloyd&#39;s material survived in later
	/// adaptations of Hitchhiker&#39;s, such as the novels and the TV series. The TV series was based on the first
	/// six radio episodes, and sections contributed by Lloyd were largely re-written. BBC Radio 4 broadcast the
	/// first radio series weekly in the UK in March and April 1978. The series was distributed in the United
	/// States by National Public Radio. Following the success of the first series, another episode was recorded
	/// and broadcast, which was commonly known as the Christmas Episode. A second series of five episodes was
	/// broadcast one per night, during the week of 21–25 January 1980. While working on the radio series (and
	/// with simultaneous projects such as The Pirate Planet) Adams developed problems keeping to writing
	/// deadlines that got worse as he published novels. Adams was never a prolific writer and usually had to be
	/// forced by others to do any writing. This included being locked in a hotel suite with his editor for three
	/// weeks to ensure that So Long, and Thanks for All the Fish was completed. He was quoted as saying, "I love
	/// deadlines. I love the whooshing noise they make as they go by." Despite the difficulty with deadlines,
	/// Adams wrote five novels in the series, published in 1979, 1980, 1982, 1984, and 1992. The books formed the
	/// basis for other adaptations, such as three-part comic book adaptations for each of the first three books,
	/// an interactive text-adventure computer game, and a photo-illustrated edition, published in 1994. This
	/// latter edition featured a 42 Puzzle designed by Adams, which was later incorporated into paperback covers
	/// of the first four Hitchhiker&#39;s novels (the paperback for the fifth re-used the artwork from the hardback
	/// edition). In 1980 Adams began attempts to turn the first Hitchhiker&#39;s novel into a film, making several
	/// trips to Los Angeles, and working with Hollywood studios and potential producers. The next year, the radio
	/// series became the basis for a BBC television mini-series broadcast in six parts. When he died in 2001 in
	/// California, he had been trying again to get the movie project started with Disney, which had bought the
	/// rights in 1998. The screenplay got a posthumous re-write by Karey Kirkpatrick, and the resulting film was
	/// released in 2005. Radio producer Dirk Maggs had consulted with Adams, first in 1993, and later in 1997 and
	/// 2000 about creating a third radio series, based on the third novel in the Hitchhiker&#39;s series. They also
	/// discussed the possibilities of radio adaptations of the final two novels in the five-book "trilogy". As
	/// with the movie, this project was realised only after Adams&#39;s death. The third series, The Tertiary Phase,
	/// was broadcast on BBC Radio 4 in September 2004 and was subsequently released on audio CD. With the aid of
	/// a recording of his reading of Life, the Universe and Everything and editing, Adams can be heard playing
	/// the part of Agrajag posthumously. So Long, and Thanks for All the Fish and Mostly Harmless made up the
	/// fourth and fifth radio series, respectively (on radio they were titled The Quandary Phase and The
	/// Quintessential Phase) and these were broadcast in May and June 2005, and also subsequently released on
	/// Audio CD. The last episode in the last series (with a new, "more upbeat" ending) concluded with, "The very
	/// final episode of The Hitchhiker&#39;s Guide to the Galaxy by Douglas Adams is affectionately dedicated to its
	/// author."
    /// 
    /// Dirk Gently series: Between Adams&#39;s first trip to Madagascar with Mark Carwardine in 1985, and their series
	/// of travels that formed the basis for the radio series and non-fiction book Last Chance to See, Adams wrote
	/// two other novels with a new cast of characters. Dirk Gently&#39;s Holistic Detective Agency was published in 1987,
	/// and was described by its author as "a kind of ghost-horror-detective-time-travel-romantic-comedy-epic, mainly
	/// concerned with mud, music and quantum mechanics". It was derived from two Doctor Who serials Adams had written.
	/// A sequel, The Long Dark Tea-Time of the Soul, was published a year later. This was an entirely original work,
	/// Adams&#39;s first since So Long, and Thanks for All the Fish. After the book tour, Adams set off on his
	/// round-the-world excursion which supplied him with the material for Last Chance to See.
	/// 
	/// Doctor Who: Adams sent the script for the HHGG pilot radio programme to the Doctor Who production office in
	/// 1978, and was commissioned to write The Pirate Planet (see below). He had also previously attempted to submit
	/// a potential movie script, called "Doctor Who and the Krikkitmen", which later became his novel Life, the
	/// Universe and Everything (which in turn became the third Hitchhiker&#39;s Guide radio series). Adams then went on
	/// to serve as script editor on the show for its seventeenth season in 1979. Altogether, he wrote three Doctor Who
	/// serials starring Tom Baker as the Doctor: "The Pirate Planet" (the second serial in the "Key to Time" arc, in
	/// season 16) "City of Death" (with producer Graham Williams, from an original storyline by writer David Fisher.
	/// It was transmitted under the pseudonym "David Agnew") "Shada" (only partially filmed; not televised due to
	/// industry disputes) The episodes authored by Adams are some of the few that were not novelised as Adams would
	/// not allow anyone else to write them, and asked for a higher price than the publishers were willing to pay.
	/// "Shada" was later adapted as a novel by Gareth Roberts in 2012 and "City of Death" and "The Pirate Planet" by
	/// James Goss in 2015 and 2017 respectively. Elements of Shada and City of Death were reused in Adams&#39;s later
	/// novel Dirk Gently&#39;s Holistic Detective Agency, in particular the character of Professor Chronotis. Big Finish
	/// Productions eventually remade Shada as an audio play starring Paul McGann as the Doctor. Accompanied by
	/// partially animated illustrations, it was webcast on the BBC website in 2003, and subsequently released as a
	/// two-CD set later that year. An omnibus edition of this version was broadcast on the digital radio station BBC7
	/// on 10 December 2005. In the Doctor Who 2012 Christmas episode The Snowmen, writer Steven Moffat was inspired by
	/// a storyline that Adams pitched called The Doctor Retires.
	/// 
	/// Music: Adams played the guitar left-handed and had a collection of twenty-four left-handed guitars when he died
	/// (having received his first guitar in 1964). He also studied piano in the 1960s with the same teacher as Paul
	/// Wickens, the pianist who plays in Paul McCartney&#39;s band (and composed the music for the 2004–2005 editions of
	/// the Hitchhiker&#39;s Guide radio series). Pink Floyd and Procol Harum had important influence on Adams&#39; work.
	/// 
	/// Pink Floyd: Adams&#39;s official biography shares its name with the song "Wish You Were Here" by Pink Floyd. Adams
	/// was friends with Pink Floyd guitarist David Gilmour and, on Adams&#39;s 42nd birthday, he was invited to make a
	/// guest appearance at Pink Floyd&#39;s concert of 28 October 1994 at Earls Court in London, playing guitar on the
	/// songs "Brain Damage" and "Eclipse". Adams chose the name for Pink Floyd&#39;s 1994 album, The Division Bell, by
	/// picking the words from the lyrics to one of its tracks, "High Hopes". Gilmour also performed at Adams&#39;s
	/// memorial service in 2001, and what would have been Adams&#39;s 60th birthday party in 2012.
	/// 
	/// Computer games and projects: Douglas Adams created an interactive fiction version of HHGG with Steve Meretzky
	/// from Infocom in 1984. In 1986 he participated in a week-long brainstorming session with the Lucasfilm Games
	/// team for the game Labyrinth. Later he was also involved in creating Bureaucracy as a parody of events in his
	/// own life. Adams was a founder-director and Chief Fantasist of The Digital Village, a digital media and Internet
	/// company with which he created Starship Titanic, a Codie Award-winning and BAFTA-nominated adventure game, which
	/// was published in 1998 by Simon & Schuster. Terry Jones wrote the accompanying book, entitled Douglas Adams&#39;
	/// Starship Titanic, since Adams was too busy with the computer game to do both. In April 1999, Adams initiated the
	/// h2g2 collaborative writing project, an experimental attempt at making The Hitchhiker&#39;s Guide to the Galaxy a
	/// reality, and at harnessing the collective brainpower of the internet community. It was hosted by BBC Online from
	/// 2001 to 2011. In 1990, Adams wrote and presented a television documentary programme Hyperland which featured Tom
	/// Baker as a "software agent" (similar to the assistant pictured in Apple&#39;s Knowledge Navigator video of future
	/// concepts from 1987), and interviews with Ted Nelson, the co-inventor of hypertext and the person who coined the
	/// term. Adams was an early adopter and advocate of hypertext.
	/// 
	/// Personal beliefs and activism: Atheism and views on religion: Adams described himself as a "radical atheist",
	/// adding "radical" for emphasis so he would not be asked if he meant agnostic. He told American Atheists that
	/// this conveyed the fact that he really meant it. He imagined a sentient puddle who wakes up one morning and
	/// thinks, "This is an interesting world I find myself in – an interesting hole I find myself in – fits me rather
	/// neatly, doesn&#39;t it? In fact it fits me staggeringly well, must have been made to have me in it!" to demonstrate
	/// his view that the fine-tuned Universe argument for God was a fallacy. He remained fascinated by religion because
	/// of its effect on human affairs. "I love to keep poking and prodding at it. I&#39;ve thought about it so much over the
	/// years that that fascination is bound to spill over into my writing." The evolutionary biologist and atheist
	/// Richard Dawkins uses Adams&#39;s influence to exemplify arguments for non-belief in his 2006 book The God Delusion.
	/// Dawkins dedicated the book to Adams, whom he jokingly called "possibly [my] only convert" to atheism and wrote on
	/// his death that "Science has lost a friend, literature has lost a luminary, the mountain gorilla and the black
	/// rhino have lost a gallant defender."
	/// 
	/// Environmental activism: Adams was also an environmental activist who campaigned on behalf of endangered species.
	/// This activism included the production of the non-fiction radio series Last Chance to See, in which he and
	/// naturalist Mark Carwardine visited rare species such as the kakapo and baiji, and the publication of a tie-in
	/// book of the same name. In 1992 this was made into a CD-ROM combination of audiobook, e-book and picture slide show.
	/// Adams and Mark Carwardine contributed the &#39;Meeting a Gorilla&#39; passage from Last Chance to See to the book
	/// The Great Ape Project. This book, edited by Paola Cavalieri and Peter Singer, launched a wider-scale project in
	/// 1993, which calls for the extension of moral equality to include all great apes, human and non-human. In 1994, he
	/// participated in a climb of Mount Kilimanjaro while wearing a rhino suit for the British charity organisation Save
	/// the Rhino International. Puppeteer William Todd-Jones, who had originally worn the suit in the London Marathon to
	/// raise money and bring awareness to the group, also participated in the climb wearing a rhino suit; Adams wore the
	/// suit while travelling to the mountain before the climb began. About &#163;100,000 was raised through that event,
	/// benefiting schools in Kenya and a black rhinoceros preservation programme in Tanzania. Adams was also an active
	/// supporter of the Dian Fossey Gorilla Fund. Since 2003, Save the Rhino has held an annual Douglas Adams Memorial
	/// Lecture around the time of his birthday to raise money for environmental campaigns.
	/// 
	/// Technology and innovation: Adams bought his first word processor in 1982, having considered one as early as 1979.
	/// His first purchase was a Nexu. In 1983, when he and Jane Belson went to Los Angeles, he bought a DEC Rainbow. Upon
	/// their return to England, Adams bought an Apricot, then a BBC Micro and a Tandy 1000. In Last Chance to See Adams
	/// mentions his Cambridge Z88, which he had taken to Zaire on a quest to find the northern white rhinoceros. Adams&#39;s
	/// posthumously published work, The Salmon of Doubt, features several articles by him on the subject of technology,
	/// including reprints of articles that originally ran in MacUser magazine, and in The Independent on Sunday newspaper.
	/// In these Adams claims that one of the first computers he ever saw was a Commodore PET, and that he had "adored" his
	/// Apple Macintosh ("or rather my family of however many Macintoshes it is that I&#39;ve recklessly accumulated over the
	/// years") since he first saw one at Infocom&#39;s offices in Boston in 1984. Adams was a Macintosh user from the time they
	/// first came out in 1984 until his death in 2001. He was the first person to buy a Mac in Europe (the second being
	/// Stephen Fry – though some accounts differ on this, saying Fry bought his Mac first. Fry claims he was second to
	/// Adams). Adams was also an "Apple Master", celebrities whom Apple made into spokespeople for its products (others
	/// included John Cleese and Gregory Hines). Adams&#39;s contributions included a rock video that he created using the
	/// first version of iMovie with footage featuring his daughter Polly. The video was available on Adams&#39;s .Mac
	/// homepage. Adams installed and started using the first release of Mac OS X in the weeks leading up to his death. His
	/// very last post to his own forum was in praise of Mac OS X and the possibilities of its Cocoa programming framework.
	/// He said it was "awesome...", which was also the last word he wrote on his site. Adams used email to correspond with
	/// Steve Meretzky in the early 1980s, during their collaboration on Infocom&#39;s version of The Hitchhiker&#39;s Guide to the
	/// Galaxy. While living in New Mexico in 1993 he set up another e-mail address and began posting to his own USENET
	/// newsgroup, alt.fan.douglas-adams, and occasionally, when his computer was acting up, to the comp.sys.mac hierarchy.
	/// Challenges to the authenticity of his messages later led Adams to set up a message forum on his own website to
	/// avoid the issue. In 1996, Adams was a keynote speaker at the Microsoft Professional Developers Conference (PDC)
	/// where he described the personal computer as being a modelling device. The video of his keynote speech is archived
	/// on Channel 9. Adams was also a keynote speaker for the April 2001 Embedded Systems Conference in San Francisco, one
	/// of the major technical conferences on embedded system engineering.
	/// 
	/// Personal life: Adams moved to Upper Street, Islington, in 1981 and to Duncan Terrace, a few minutes&#39; walk away,
	/// in the late 1980s. In the early 1980s Adams had an affair with novelist Sally Emerson, who was separated from her
	/// husband at that time. Adams later dedicated his book Life, the Universe and Everything to Emerson. In 1981 Emerson
	/// returned to her husband, Peter Stothard, a contemporary of Adams&#39;s at Brentwood School, and later editor of The
	/// Times. Adams was soon introduced by friends to Jane Belson, with whom he later became romantically involved. Belson
	/// was the "lady barrister" mentioned in the jacket-flap biography printed in his books during the mid-1980s
	/// ("He [Adams] lives in Islington with a lady barrister and an Apple Macintosh"). The two lived in Los Angeles
	/// together during 1983 while Adams worked on an early screenplay adaptation of Hitchhiker&#39;s. When the deal fell
	/// through, they moved back to London, and after several separations ("He is currently not certain where he lives,
	/// or with whom") and a broken engagement, they married on 25 November 1991. Adams and Belson had one daughter together,
	/// Polly Jane Rocket Adams, born on 22 June 1994, shortly after Adams turned 42. In 1999 the family moved from London to
	/// Santa Barbara, California, where they lived until his death. Following the funeral, Jane Belson and Polly Adams
	/// returned to London. Belson died on 7 September 2011 of cancer, aged 59.
	/// 
	/// Death and legacy: Adams died of a heart attack on 11 May 2001, aged 49, after resting from his regular workout at a
	/// private gym in Montecito, California. Adams had been due to deliver the commencement address at Harvey Mudd College
	/// on 13 May. His funeral was held on 16 May in Santa Barbara. His ashes were placed in Highgate Cemetery in north
	/// London in June 2002. A memorial service was held on 17 September 2001 at St Martin-in-the-Fields church, Trafalgar
	/// Square, London. This became the first church service broadcast live on the web by the BBC. Video clips of the
	/// service are still available on the BBC&#39;s website for download. One of his last public appearances was a talk given
	/// at the University of California, Santa Barbara, Parrots, the universe and everything, recorded days before his death.
	/// A full transcript of the talk is available, and the university has made the full video available on YouTube. Two
	/// days before Adams died, the Minor Planet Center announced the naming of asteroid 18610 Arthurdent. In 2005, the
	/// asteroid 25924 Douglasadams was named in his memory. In May 2002, The Salmon of Doubt was published, containing many
	/// short stories, essays, and letters, as well as eulogies from Richard Dawkins, Stephen Fry (in the UK edition),
	/// Christopher Cerf (in the US edition), and Terry Jones (in the US paperback edition). It also includes eleven
	/// chapters of his unfinished novel, The Salmon of Doubt, which was originally intended to become a new Dirk Gently
	/// novel, but might have later become the sixth Hitchhiker novel. Other events after Adams&#39;s death included a webcast
	/// production of Shada, allowing the complete story to be told, radio dramatisations of the final three books in the
	/// Hitchhiker&#39;s series, and the completion of the film adaptation of The Hitchhiker&#39;s Guide to the Galaxy. The film,
	/// released in 2005, posthumously credits Adams as a producer, and several design elements – including a head-shaped
	/// planet seen near the end of the film – incorporated Adams&#39;s features. A 12-part radio series based on the Dirk Gently
	/// novels was announced in 2007. BBC Radio 4 also commissioned a third Dirk Gently radio series based on the incomplete
	/// chapters of The Salmon of Doubt, and written by Kim Fuller;[66] but this was dropped in favour of a BBC TV series
	/// based on the two completed novels.[67] A sixth Hitchhiker novel, And Another Thing..., by Artemis Fowl author Eoin
	/// Colfer, was released on 12 October 2009 (the 30th anniversary of the first book), published with the support of
	/// Adams&#39;s estate. A BBC Radio 4 Book at Bedtime adaptation and an audio book soon followed. On 25 May 2001, two weeks
	/// after Adams&#39;s death, his fans organised a tribute known as Towel Day, which has been observed every year since then.
	/// In 2011, over 3,000 people took part in a public vote to choose the subjects of People&#39;s Plaques in Islington;
	/// Adams received 489 votes. On 11 March 2013, Adams&#39;s 61st birthday was celebrated with an interactive Google Doodle.
	/// In 2018, John Lloyd presented an hour-long episode of the BBC Radio Four documentary Archive on 4, discussing Adams&#39;
	/// private papers, which are held at St John&#39;s College, Cambridge. The episode is available online. A street in
	/// S&#227;o Jos&#233;, Santa Catarina, Brazil is named in Adams&#39; honour.
	/// 
	
contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract HHGTTG is StandardToken { // Contract Name.

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   // Token Name
    uint8 public decimals;                // How many decimals to show. To be standard compliant keep it at 18
    string public symbol;                 // An identifier: e.g. h2g2, HHGTTG, HG2G, etc.
    string public version = &#39;H1.0&#39;; 
    uint256 public unitsOneEthCanBuy;     // How many units of your coin can be bought by 1 ETH?
    uint256 public totalEthInWei;         // WEI is the smallest unit of ETH (the equivalent of cent in USD or satoshi in BTC). We&#39;ll store the total ETH raised via our ICO here.  
    address public fundsWallet;           // Where should the raised ETH go?

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function HHGTTG() {
        balances[msg.sender] = 42000000000000000000;	// Give the creator all initial tokens. This is set to 42.
        totalSupply = 42000000000000000000;				// Update total supply (42)
        name = "HHGTTG";								// Set the name for display purposes.
        decimals = 18;									// Amount of decimals for display purposes.
        symbol = "h2g2";								// Set the symbol for display purposes
        unitsOneEthCanBuy = 1;							// Set the price of token for the ICO
        fundsWallet = msg.sender;						// The owner of the contract gets ETH
    }													// REMEMBER THIS TOKEN HAS ZERO MONETARY VALUE!
														// IT IS NOT WORTH THE COST TO PURCHASE IT!
														// PLEASE REFRAIN FROM BUYING THIS TOKEN AS IT
														// IS NON-REFUNDABLE!
    function() payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);                               
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}