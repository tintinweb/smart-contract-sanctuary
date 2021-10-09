pragma solidity 0.8.7;
 
import "./token.sol";
import "./ownable.sol";
import "./tokenMeta.sol";
import "./erc721.sol";
 
contract newNFT is NFTokenMetadata, Ownable {
 
    uint256 constant supply = 146;  //replace this with your max NFTS
    uint256 currentID = 0;
    string[] uIDs = [ //replace this list with your IPFS links
      "https://ipfs.io/ipfs/QmVBBF2rzKx9GVHt31WKBYzxU2qjX6jzd1Zi5DUp7TqRvo?filename=2x%20Pizza%20%3D%2010k%20BTC.json",
      "https://ipfs.io/ipfs/QmatyAeVdvPeZdo5QrfQNxm7oEgipqp1cU3aZX9iaLBVfv?filename=Changpeng%20Zhao.json",
      "https://ipfs.io/ipfs/QmR6s1QMULfMRtFTSTanXydcfPTZceMZEVTsxwzaCpk7HD?filename=Adam%20Back.json",
      "https://ipfs.io/ipfs/QmZN1zwiCw6nvKth8FZMCSsaq94vCyyTTWdinj3NHv6hbm?filename=Amber%20Baldet.json",
      "https://ipfs.io/ipfs/QmQpxNmAFbvQ6NYb51tXFfZMpAsuSv3arbEdCRXpKMv6nt?filename=Andre%20Cronje.json",
      "https://ipfs.io/ipfs/QmXKfujRu641rxiKkYniMUnx1QFiKPb9ruiRq5xy6KAzK5?filename=Andreas%20Antonopoulos.json",
      "https://ipfs.io/ipfs/QmP265c5sA2AcLncX69tNtV9XbRShG4QuzFLDw7JUN3e4P?filename=Anthony%20Pompliano.json",
      "https://ipfs.io/ipfs/QmbhrbfHjCLq5LL6cxnwJk8QMja8hCMf8kBEtoT9Yessz7?filename=Ari%20Paul.json",
      "https://ipfs.io/ipfs/QmZR3HkMDdYSLTkix6REgPKVqYNjyqxmX6uTDKSHrXS9Cs?filename=Arianna%20Simpson.json",
      "https://ipfs.io/ipfs/QmXyyEvtACUDb1jVJAYa1iQz3NY5mgtvsYd92aJR9djpdS?filename=Barry%20Silbert.json",
      "https://ipfs.io/ipfs/QmRzghDfNeoLpx79jKUEiRBNXwz1ZKnsJX4J8C43tQsR9m?filename=Bart%20Stephens.json",
      "https://ipfs.io/ipfs/QmenaaE4GdqdxrC4ENDg5HEjRbtCQ2GXp4PSA32AyoKiBy?filename=Beeple%20NFT%20Auction.json",
      "https://ipfs.io/ipfs/QmZnVo4sSoPu41k9Lp6Jgd2khtaJ8MrhfA8ZmteqVn6w1k?filename=Bekker.json",
      "https://ipfs.io/ipfs/QmXTaSxjfHMANcej5Jj2AY18tQ9YM1rPm14tqQVCcNMHc5?filename=Ben%20Goertzel.json",
      "https://ipfs.io/ipfs/QmTzDGWSiXdugukmB1vcf6N9nfT68yZffrVCGK2BkBEXpu?filename=Bitcoin%20ATM.json",
      "https://ipfs.io/ipfs/QmYdiTG76pBf2iXTRezB1MdispLoWYtjaWp2WmksCzk5P2?filename=Bitcoin%20going%20down.json",
      "https://ipfs.io/ipfs/QmY9o3LUN7yscJd2toRbjjf7TrNiWHN8e7tDhZzgsru4NL?filename=Bitcoin%20whitepaper.json",
      "https://ipfs.io/ipfs/QmXJYyDgSjSvQVgyRy9ySmWJ4adJNpZNW4QyceHU4qvzuR?filename=BitPay%20Launches!.json",
      "https://ipfs.io/ipfs/QmUB4XCkegmNdBRNDaQ2GXsjnX4pke41qyFJjQszfXrNHX?filename=Bobby%20Lee.json",
      "https://ipfs.io/ipfs/QmaHjr8yNnqBhhQrrmbEjHJvWTTYd1j8wv11u1D9pNyMay?filename=Bobby%20Ong.json",
      "https://ipfs.io/ipfs/QmZatq31oHxrFhgR4tVBVuTfyMSyP3AQtK7yRRQZVFSrYF?filename=Brad%20Garlinghouse.json",
      "https://ipfs.io/ipfs/QmY6CunssAnuNApPukMbLUHneftuvH1QvdgqeMVteq6mx9?filename=Brandon%20Chez.json",
      "https://ipfs.io/ipfs/QmZ6myREi99QGQEwhenGTjawRtVBarBdyo23icfa7FtZqL?filename=Brendan%20Blumer.json",
      "https://ipfs.io/ipfs/QmPZdJAmYnLVcZEL2JsMERirosKbdQxerDAWau1Eahypjn?filename=Brian%20Armstrong.json",
      "https://ipfs.io/ipfs/QmU3rJHBRheGrhzs92Egf5WLg59UYTmnLhnGgr9k1piitR?filename=Buying%20Mcdonalds%20with%20BTC.json",
      "https://ipfs.io/ipfs/QmQkkdc344ddj1MTjkVgexrxbzRENtD6wtdVMc67N3wDfG?filename=Caitlin%20Long.json",
      "https://ipfs.io/ipfs/QmRm6Rz4o8tryqsHeHm44EiHYZWirH2s1zzDFqzG3TyT3y?filename=Catherine%20Coley.json",
      "https://ipfs.io/ipfs/QmSJKrjBX2t1D9cBsSRgSqQyyQqUNNJXyzwsgVSEF8YVLi?filename=Cathie%20Wood.json",
      "https://ipfs.io/ipfs/QmXUDcuTVCyYB2Qzj6foGoX6SwYhPhZDPHEnfzTMXQXBnq?filename=Chamath%20Palihapitiya.json",
      "https://ipfs.io/ipfs/QmatyAeVdvPeZdo5QrfQNxm7oEgipqp1cU3aZX9iaLBVfv?filename=Changpeng%20Zhao.json",
      "https://ipfs.io/ipfs/QmQtJLkyWxtcqkPsKGigqCNXgCaQ8Ba679oiZnLnHPYiSp?filename=Charles%20Hoskinson.json",
      "https://ipfs.io/ipfs/QmQZuwLJ4XeGEjvMjj2jc2zARd59rgKbGDHnjxKR7Xv15h?filename=Charlie%20Lee.json",
      "https://ipfs.io/ipfs/QmaHgdZD8HLnw7APXKdr2yPbtHSWPNre4MmZCtoRMcH8d6?filename=Charlie%20Shrem.json",
      "https://ipfs.io/ipfs/Qmd8XPpTN8h6WaPqnfoZ8w8Cyb2bEJ93rRNgVarMTck6tK?filename=China%20Bans%20mining.json",
      "https://ipfs.io/ipfs/QmeUoEmnFHDNYWJMP8V2XgE7ubEYLrZq34FTCZ2atGfZNK?filename=China%20FUD.json",
      "https://ipfs.io/ipfs/QmYUg4PFBLZPoXkVLUqjyoPh8r3Vn8QTcaa1RBhdqPEhmp?filename=Chris%20Dixon.json",
      "https://ipfs.io/ipfs/QmR1n6fsDe5NiL3JxMXLLGxisVarnwQrMziA8meQPPJSjK?filename=Crypto%20reaches%20wallstreet.json",
      "https://ipfs.io/ipfs/QmSJWi8JQjkKhtn5HKHDLj1zUSaB9Eu8DFuDbYfFYrKHYT?filename=Cryptopunk.json",
      "https://ipfs.io/ipfs/QmUrPzQHF2Hyhk43HgCoGVoRAuxBeeJN9YexdqcHsD9c5L?filename=Dan%20Held.json",
      "https://ipfs.io/ipfs/QmTycsozv31gokhBRCLYKm4gcAhvWyk1P3gmxnkCGDWPjW?filename=Dan%20Morehead.json",
      "https://ipfs.io/ipfs/QmZEdKeUFYerSpseaLT1o4FeQqnuVK4waV1NWRcUaBQ6rX?filename=Dan%20Schulman.json",
      "https://ipfs.io/ipfs/QmTgfYCwfyUBhMivEda9hFMDcd27A9vEbPvcsjLAnfQenS?filename=Danny%20Ryan.json",
      "https://ipfs.io/ipfs/QmYKRgKLHzJ4iMTou8bv5mgtvcFdnEJ8PB4P9qddFdS8Ey?filename=Diamond%20hands.json",
      "https://ipfs.io/ipfs/QmUx9PWAS5DGjPKbdRogfjEZTFdA5uVcFpLKFSd9CVQ6Pa?filename=Do%20Kwon.json",
      "https://ipfs.io/ipfs/QmVnitc6P7CZvEYt4zapmLfLeWYW9Yj2zJGAbx1nhhAtfa?filename=DOGE.json",
      "https://ipfs.io/ipfs/QmbwyYqxbpbCesAbPzbqBdeGXwLaLwPhfHENbUZGseXZNn?filename=Dominik%20Schiener.json",
      "https://ipfs.io/ipfs/QmX5MShfGeUhoqoHrvuyGUWreug5aX4z2SNuAxaXdMcUY8?filename=El%20Salvador%20accepts%20BTC.json",
      "https://ipfs.io/ipfs/QmRKhj4dPqQxDJo7koxLgX1L3PYdSTPe9Txs2CHJa7SVjT?filename=Elizabeth%20Stark.json",
      "https://ipfs.io/ipfs/QmdsN1L2cWtujSE35cbLXsBjnNgXwa9pncNFvQtJrfmWhV?filename=EllioTrades.json",
      "https://ipfs.io/ipfs/QmZqxQLgabXzS6hhK46Pj4RbnFL6WN7EtcYkoWYALyD6tU?filename=Elon%20Holding%20Doge.json",
      "https://ipfs.io/ipfs/QmVXDKkkzvsxUdzSpL4nvBNA1drmgrdFKqZjQKvcwe1hz9?filename=Elon%20Musk.json",
      "https://ipfs.io/ipfs/QmY2qm3rqV3fXMLJv7ogbZs6n1mvvsLtF8KwAhEXXwd9nV?filename=Emin%20Gu%CC%88n%20Sirer.json",
      "https://ipfs.io/ipfs/Qmes87TcUQoXuTWm12KqDGuqskuHH14dPwfSu9dcg3y2Ki?filename=Eric%20Larcheve%CC%82que.json",
      "https://ipfs.io/ipfs/QmRhFAjzrqKVj4rio8kTPv1aTG1BaZjk2NJsd4sHuJZiLA?filename=Erik%20Voorhees.json",
      "https://ipfs.io/ipfs/QmdeX9Q98hRDLnVPDcd6VRHhxKyp3ofrUow372BHuDGd5U?filename=ETH%202.0.json",
      "https://ipfs.io/ipfs/QmPUaj51kzhZiEWLheDM4XMejRRFzozvPDBGSuFpKqPrEs?filename=Evan%20Kuo.json",
      "https://ipfs.io/ipfs/QmQDP9kN4JiNJjXjAGHrKbLrkpzwQPKHZfjskLUmFKyW35?filename=Fred%20Ehrsam.json",
      "https://ipfs.io/ipfs/QmWuU9wH69A9B4EeWT8K1rpBmDiBhgTtEAXB6FTNS3Q5or?filename=Gavin%20Andresen.json",
      "https://ipfs.io/ipfs/QmURcSFcQcUJR3u4D34ywRyjq3p7RiVrz9bQfXKrMZ3JHK?filename=Gavin%20Wood.json",
      "https://ipfs.io/ipfs/QmQcsYBCwguWfthcn2wHm5n3pDf8W1cGpVhYoZsvaWmDm5?filename=Genesis%20block.json",
      "https://ipfs.io/ipfs/QmTorzBRjojgotT6hHV7dEHAuDJtBZMZEpsapaQPbVb2Um?filename=Halfin%20Tweet.jpg",
      "https://ipfs.io/ipfs/QmNQXgruC2pJVBDAVePHxm7bUSk5GJvoAWW9pwH5xNL3GQ?filename=Hayden%20Adams.json",
      "https://ipfs.io/ipfs/QmRZuUgc15XB5FmS2KSk54uVYGNWYCkAqs12Zh2czLfeaT?filename=Jack%20Dorsey.json",
      "https://ipfs.io/ipfs/QmNZUYXKvCGUNE1VtKP67GppsLrBnz5LCE3pC2kVRVLf83?filename=Jake%20Brukhman.json",
      "https://ipfs.io/ipfs/QmVkGV2VCHyq4WWJRPmGAX2RxU8E1PbCZXXTT7URbVh4Wa?filename=Jameson%20Lopp.json",
      "https://ipfs.io/ipfs/QmXa84atGziJUajqoK8pwekPgW7iFatA5Dp6gvqZKgUpSs?filename=Jean-Louis%20van%20der%20Velde.json",
      "https://ipfs.io/ipfs/QmPQKQ4JGTrkPvbpXtMWkwfdfuTNLk72PGuYruoJsyNn2m?filename=Jed%20McCaleb.json",
      "https://ipfs.io/ipfs/QmNSZFYVoMArpL2KS7yCx35pb1yNofc8qGaguoPyt6Az8j?filename=Jeremy%20Allaire.json",
      "https://ipfs.io/ipfs/QmcoeuJ66ERgxUnA1ZsMR7Mw4n4KgrMkogsZVpZnhYFjBa?filename=Jesse%20Powell.json",
      "https://ipfs.io/ipfs/QmZh1eV6ek45yV713RDk8koufaHSTxAtsguv7VLHT6GxzY?filename=Jihan%20Wu.json",
      "https://ipfs.io/ipfs/QmaorGwW2QjT8jJ8gMytDWLNrEhv7YyG7ECgGvtqBG5JHa?filename=Jinglan%20Wang.json",
      "https://ipfs.io/ipfs/QmWoXKjnuBDxWTdd4865CXTBjUbZsN4uNENSrkL2UyYdaB?filename=John%20McAfee.json",
      "https://ipfs.io/ipfs/QmfW5iWRG3BjmPBcdu9Aq9Nc1ZgzYcHoPm1iUuu9RskGqJ?filename=Joseph%20Lubin.json",
      "https://ipfs.io/ipfs/QmRzbpa9bj6eYMZJkgDA3yZxxzZvpWBkstLAU7b14k49wy?filename=Joyce%20Kim.json",
      "https://ipfs.io/ipfs/QmVywsDLbdnYQLhtWQQuRxZz3iE3EXXcgbMA7GtTt4r8cP?filename=JRNY.json",
      "https://ipfs.io/ipfs/QmfJBC1pqrRuWiQnXHkMVrWgrveB9qhDLrsQsccVDb5Ha4?filename=Justin%20Sun.json",
      "https://ipfs.io/ipfs/QmTE5gV3erY56ptk1yRLbNM76TBEYreRVa384cWLjX5qJQ?filename=Kain%20Warwick.json",
      "https://ipfs.io/ipfs/Qmefkc6KyHJGDDNNwiN7Fz3E6wTrM3U6Gay9KEdPN4sd7F?filename=Kathleen%20Breitman.json",
      "https://ipfs.io/ipfs/Qmewucuuezep2ovBdwcgPpeknr2Yx1xfLWaZcocbhgd5T2?filename=Kathryn%20Haun.json",
      "https://ipfs.io/ipfs/QmY2X6HZWuEgWyfwcG1BdSsGFJ3kQRmaEaefyYXJZuouno?filename=Kris%20Marszalek.json",
      "https://ipfs.io/ipfs/QmUPgCBsgpZTrHdwSopdT2NRspNA4ogy2VfPhknq4BDakV?filename=KSI%20Tweet.json",
      "https://ipfs.io/ipfs/QmPEW987o98b2bjTVmgPuiLTQK9GmaaQvBTKtie6DEsCQ8?filename=Lark%20Davis.json",
      "https://ipfs.io/ipfs/QmfNcqU5A2EszJWYThEYRWTnEnVNPpEN5mVXTZcpBDoNq6?filename=Laura%20Shin.json",
      "https://ipfs.io/ipfs/QmefmuKafq4oHiT4UZG8bM7FE6z7dFneb7KzknaQHAz7sP?filename=Marc%20Andreessen.json",
      "https://ipfs.io/ipfs/QmVSC3wuxhPZb34To4bjDCLBdpexzk8bFVFQ375hySnjfj?filename=Linda%20Xie.json",
      "https://ipfs.io/ipfs/Qmcrf5A3TobJbYYRvq61rkbJBvAwiFeg59pcwqPgykuM9b?filename=Matthew%20Roszak.json",
      "https://ipfs.io/ipfs/QmNgFdgMJPLRDZP3JXiyRqR7C6jcXYRnn5EAgu7L2U2PHa?filename=Meltem%20Demirors.json",
      "https://ipfs.io/ipfs/QmeYNEkUiQbkykMotjAwBt3JFDqU3dkEmFPbpeX3R7RJQ6?filename=Michael%20Saylor.json",
      "https://ipfs.io/ipfs/QmcEz6nbJZZYd49KnHn7iKUnZi14SCJ1z1Bet4JKVsEwjr?filename=Microsoft%20Accepts%20Bitcoin.json",
      "https://ipfs.io/ipfs/QmdJD8n9XnHErHAiVfSEG9TpRB9qq5TyYYYCCm6jQ4mpdW?filename=Mike%20Belshe.json",
      "https://ipfs.io/ipfs/QmSotLNAyHE2XvRfP7frDNqVRda5SbR1i5rLDu5T7RAUya?filename=Mike%20Novogratz.json",
      "https://ipfs.io/ipfs/QmbBuaHEJzZ1UWZXRLfqxCsgkPqsjuCFUho58XKoijJD3H?filename=Mike%20Winkelmann.json",
      "https://ipfs.io/ipfs/QmRiyfchfF9HgemmLC8Vos7fwTwqNLT881gGHCyStSuQXd?filename=Money%20Printer.json",
      "https://ipfs.io/ipfs/QmSfJ796CfzZDb5M1AxCvQUAEbGtF5oD5pFBs1em97NJCq?filename=Mt%20Gox.json",
      "https://ipfs.io/ipfs/QmV396Qny1qsvvkGajqJybGowmmqU36iLEZL3WonXrmCPT?filename=Muneeb%20Ali.json",
      "https://ipfs.io/ipfs/QmUruGX5vPrd8U83QjSCdAzEKTVkRHQ1gnt5E4r7Az7Ddj?filename=Naval%20Ravikant.json",
      "https://ipfs.io/ipfs/QmPPRde1NtYDksBDVp4NN2joYTbVa1bVPAHCXFFFCTARXx?filename=Nejc%20Kodric.json",
      "https://ipfs.io/ipfs/QmSHHjkDNn1xZaXnAC8RaeS9rpfuaugqZ6cjvmoRjBDF2N?filename=Nick%20Szabo.json",
      "https://ipfs.io/ipfs/QmUL89yAWspdw1um7U1yDVPbePN8wGs88irJUSAE9BHNp1?filename=Olaf%20Carlson-Wee.json",
      "https://ipfs.io/ipfs/QmRx8Ai4jLd9RZhjqUKPyYz3VJ47C4VEn5UZh2BBqRiP6D?filename=Paper%20hands.json",
      "https://ipfs.io/ipfs/QmWDTTLX3zUi73DeXdgah4K7vy3viDgVDdPmomhWcE65ii?filename=Paul%20Tudor%20Jones.json",
      "https://ipfs.io/ipfs/QmXH7s1YsNWew9mrcu4z8AapJeyFwWXZoUagKvxBogWsKW?filename=Pavel%20Durov.json",
      "https://ipfs.io/ipfs/QmcQT1FsJ6Tf9knUmvVyYooT3kV7ChcrTUDzR7EApEcfdd?filename=Paypal%20accepts%20BTC.json",
      "https://ipfs.io/ipfs/QmXpyruiKYvLwqpSFjpsBKs5RLbqw2q2KpsjhAjeso32pb?filename=Peter%20Schiff.json",
      "https://ipfs.io/ipfs/QmW611jjAiaUWVCgfkHhgA5eoM9bm56VvikesoFLi4X6kB?filename=Peter%20Smith.json",
      "https://ipfs.io/ipfs/QmeriHzZ1zjDm1F52b8QUMfp8Ytrm9PwewR1nwvi4YxEC2?filename=Pieter%20Wuille.json",
      "https://ipfs.io/ipfs/QmSTi3TK4QGSEE7k8i6nsUHLadeaCeiwEuZdE5A9begwdh?filename=Plan%20B%20-%20Stock%20to%20Flow%20Model.json",
      "https://ipfs.io/ipfs/QmXTMNf5PV1Q6rjoPUcqGzZCUjfYf2MKqDpnhX3Dd4J5Wt?filename=Preethi%20Kasireddy.json",
      "https://ipfs.io/ipfs/QmZgajdCfuvfUFX1bj7NKbFbfScWoWLFzwXSVYoTkWJNMQ?filename=Ran%20NeuNer.json",
      "https://ipfs.io/ipfs/QmPvTD2s6jmPhurhqoaKUv26sjxipnzyjagFDWUtLs5egj?filename=Raoul%20Pal.json",
      "https://ipfs.io/ipfs/QmVHGwrjBwfugJSSGKBnwbXNGJvMzm2EpsPyVaMDXtkRHa?filename=Robert%20Leshner.json",
      "https://ipfs.io/ipfs/Qmeu4mVnJ464LtH8UwMgveFVLGbqMKihw5a6vj5sFmLZGc?filename=Roger%20Ver.json",
      "https://ipfs.io/ipfs/QmQGDiDLJrf35SHfq2vPijUpUwAPqrS58vg4XVFkq8vDpr?filename=Rune%20Christensen.json",
      "https://ipfs.io/ipfs/QmXEAn5rzm5ZeALYjXmk4bWBrjYfDWaKJXUEF7BE5VFpSN?filename=Ryan%20Selkis.json",
      "https://ipfs.io/ipfs/QmYGLZrCqArGg9B5SfjNATwm42kbuAyzjKTd6mUQp9GW79?filename=Sam%20Bankman-Fried.json",
      "https://ipfs.io/ipfs/Qmf8xwdDKzjmyhavEr4n95TKeHEmLthPKm8VsHuRxiWZpL?filename=Sam%20McIngvale.json",
      "https://ipfs.io/ipfs/QmQwzpSanR2WqE8yjtdhCSE2wqK59o7Q26Kia2NbEHXPxG?filename=Satoshi%20Statue.json",
      "https://ipfs.io/ipfs/QmQ438Cp5dToQbgreLRyRwhVqPe25ie7tA7RcUyobhvKvc?filename=Sergey%20Nazarov.json",
      "https://ipfs.io/ipfs/QmRq5yLa21FduPrc8K1T8zRYps5pPzz2q6wSwtUXPcs8w8?filename=Shitcoin.json",
      "https://ipfs.io/ipfs/QmY4VLmdEGNSuLh11ShLajfLLYyyaEYUd8oS18jYjDMMkC?filename=Snoop%20Dogg.json",
      "https://ipfs.io/ipfs/QmfAfpEjLjaRBCUKpHtRiVZwPgThDpPs8U17xcsYm3CVAZ?filename=Soravis%20Srinawakoon.json",
      "https://ipfs.io/ipfs/QmXifEgTgFuLQqkxz21sZBPqDTZp4d2nxmss3mdSegJyuQ?filename=Stan%20Druckenmiller.json",
      "https://ipfs.io/ipfs/QmNnCJdHwvhNULXzJ3PqNk5Wa5AUg6CzDg5Un5t73m4Toz?filename=Stephen%20Pair.json",
      "https://ipfs.io/ipfs/QmdCN3zzwfJtZo1jXbxAf3MAPB3EefLwCFg7CUDuudXbeV?filename=Tesla%20buy's%20bitcoin.json",
      "https://ipfs.io/ipfs/QmWyHd1w7YqbcTpVduJSrWg9qiwFX8SE4YKfptcAWdpbXb?filename=The%202008%20Financial%20Crisis%20%3D%20Birth%20of%20BTC.json",
      "https://ipfs.io/ipfs/QmRCN5zckafZMkaiXZi5JELPVWuVUGB9Rg2cuN7r14D9JY?filename=The%20B%20Word%20Event.json",
      "https://ipfs.io/ipfs/QmTLfVKay15p4zJJcsDE18sLBEtGnkYjuMzT1CEDTjuLYj?filename=The%20Birth%20of%20HODL.json",
      "https://ipfs.io/ipfs/QmT8bWhoEoGPUBC1dkoBYDpNMhHTE3z2hffygr7qgBCyww?filename=The%20First%20Halving.json",
      "https://ipfs.io/ipfs/Qmco3vV3rJLi9iewZMhuCGccTLo6Z67jrB2ZNffzRkxcsG?filename=The%20future%20millionaires.json",
      "https://ipfs.io/ipfs/QmZf18w338n8yEV7T9gHipwfmWGFcgQFA3aAuT36v69jUi?filename=The%20Sign%20Guy.json",
      "https://ipfs.io/ipfs/QmexJgTS1jvtrbxVdDUXdvBTGo4xAUGtXoNFnHUG9AJLtz?filename=Tim%20Draper.json",
      "https://ipfs.io/ipfs/QmVGq34cAbfrcdHtwhFe92skCZUyvuuPjbcRvJ1EYgmcew?filename=Transaction%20speed%20Meme.json",
      "https://ipfs.io/ipfs/QmSmaXG7SZxK374xKYzNH7uM8GNyVBCbt1iBCB4hiZAkgm?filename=Twitter%20adds%20BTC%20tipping.json",
      "https://ipfs.io/ipfs/QmTf5jVH3rQP8DehT1ohhBaLQ5euNBoJJwnv6VkkLV5vFs?filename=Valery%20Vavilov.json",
      "https://ipfs.io/ipfs/QmeGP42FuB68v6gsad1sexwQbXBUKC4tmAyDxBogJGYbcn?filename=Vansa%20Chatikavanij.json",
      "https://ipfs.io/ipfs/QmaKt9xkRH7Kda9DN2V5nKhMiccMfNdEGsdUZAPb9QMGX7?filename=Vinny%20Lingham.json",
      "https://ipfs.io/ipfs/QmQoM3E5pxaQYNLyuAhio7nV1gatoFbRCK2WFaAvteCGfX?filename=Visa%20buys%20a%20Punk.json",
      "https://ipfs.io/ipfs/QmPos7G4TnZ1t682mNswzFjgZkgXZhJfQmQNtf2muYNJ3t?filename=Vitalik%20Buterin.json",
      "https://ipfs.io/ipfs/QmSUdu5HU3xhyr8hKCmg8je9sCcRm4crRtPRWap11vHpvm?filename=Vitalik%20will%20leave!.json",
      "https://ipfs.io/ipfs/QmZgBKf8LWd925Bdcj5gj4h8R9jJKQRDgDze9AExX4DToC?filename=Warren%20Buffet.json",
      "https://ipfs.io/ipfs/QmUSAsSVo1rd5g6kMTWTSGTrVFHmYE1uYYzSU6itKkn3s5?filename=Willie%20Woo.json",
      "https://ipfs.io/ipfs/QmcX6PkfJT3bgkYndQU4n9QQ9H3ZXxxw8Mu4E9CywzEAsm?filename=Winklevoss%20Twins.json",
      "https://ipfs.io/ipfs/QmNrsPDM5XyBmJXU4apb5VoEUSfAfpF9Mht17fPVCHdib6?filename=Wyckoff%20distribution.json",
      "https://ipfs.io/ipfs/QmPNqzoTxicm13gz5Eqs5RTB3pkqisfbV1AEvn8azgnHkb?filename=Xi%20Jinpingg.json",
      "https://ipfs.io/ipfs/QmVVtmdDQz76UKUgy86AK9WPLo1rNsSi5H1UogUzajuoeB?filename=XRP%20gets%20sued.json",
      "https://ipfs.io/ipfs/QmUqvi45SXXf3fHM4yy89thXTojNVQ5mVyQn1WES54RGD4?filename=Zac%20Prince.json"
      ]; 
  constructor() payable {
    nftName = "The Crypto History Book";
    nftSymbol = "CHBNFT";
  }
  fallback() external payable { }
  receive() external payable { }
 //10000000000000000
  function mint(address _to) public payable {
    require(_getOwnerNFTCount(msg.sender) < 5, "Each address may only own five CHBNFTs"); //replace the number with your limit per address
    require(currentID<supply, "Max Supply Reached");
    require(msg.value >= 150000000000000000 wei, "Invalid ETH Amount"); //replace the 10 wei with the price of your NFT in wei
    currentID = currentID+1;
    
    uint256 _tokenId = currentID;
    string memory _uri = uIDs[currentID-1];
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }  
  function extractEther() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
 
}