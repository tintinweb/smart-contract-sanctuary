/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

/** 
 *  SourceUnit: d:\repos\NFTurbo\contracts\emptybunnies\emptybunnies_royalties.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

//
//                               *     (               )                   )     )  (         (
//                             (  `    )\ )  *   )  ( /(     (          ( /(  ( /(  )\ )      )\ )
//                        (    )\))(  (()/(` )  /(  )\())  ( )\     (   )\()) )\())(()/( (   (()/(
//                        )\  ((_)()\  /(_))( )(_))((_)\   )((_)    )\ ((_)\ ((_)\  /(_)))\   /(_))
//                       ((_) (_()((_)(_)) (_(_())__ ((_) ((_)_  _ ((_) _((_) _((_)(_)) ((_) (_))
//                       | __||  \/  || _ \|_   _|\ \ / /  | _ )| | | || \| || \| ||_ _|| __|/ __|
//                       | _| | |\/| ||  _/  | |   \ V /   | _ \| |_| || .` || .` | | | | _| \__ \
//                       |___)|_(  |_||_|    |_|    |_|    |___/ \___/ |_|\_||_|\_||___||___||___/
//
//                                                   ( /(  )\ )   *   )
//                                                   )\())(()/( ` )  /(
//                                                  ((_)\  /(_)) ( )(_))
//                                                   _((_)(_))_|(_(_())
//                                                  | \| || |_  |_   _|
//                                                  | .` || __|   | |
//                                                  |_|\_||_|     |_|
//
//                                               (--Royalties Contract--)
//
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0KXNWWXOkO00KKKXKOxxxxxxxxxxxxxxxxxxxxoc;cdxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOKXNNXOdxXWXKK0Okkxx0Kkxxxxxxxxxxxxxxxdoc;,'.,oxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOKNNKOdc:;oOkdocc:;:lxKX0kxxxxxxxxxxxxdc;,''',''lxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkOOOOOOKNNOlc:cc;;cc:ccccokKXXK0XKkxxxxxxxxxdc,'''..''''lxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkOKKXK0Okxddxxko:ccccc::cccc;,:odolc:cOXkxxxxxxxxo;.'.....''''lxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOKXXKOxoc;;,'....';:::::ccc::::;;;::cc:ckNXOkxxxxxxd:......''''.,oxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxO00Odc;,''','..',;:cllccc:::clooddooolc:',oOXNX0kxxxxd;......''''':dxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl:,,,;,'..................'''''''',;::;,,;;;,'...;oOOOxdddd;.....''..'cdxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxxxdl;'...............'''''''''''''''';:c::;;:,...........',,,,;;'.......':oxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxxdl;..'''''......'..''''''''''',,,,,;cc:cc::,;:::,''''''''''''''... .....'cdxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxxd:'.'''''''''''''''''''''''''''clc::cc;,;:::::;;c:,,,,,,,''''''''....'''..';lxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxxd;...'''''''''...''''....''''''',cc;;::::''';l:;:c;'''',,,,,''''......'''','.;dxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxxd:................................';;:c:;:::,;ll:;,'''''',,,,,,,''......'''''.;dxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxxxkl..........''.';::cc:'........,clcccccclllllcc:,'........'''''''''...........'lxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxxx00c..'',,'';::;;okOOOko;,''.....,oOOOOOOOOOOOkkkxd;................'''.........:xxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxxk0NXc';:cc;;ccc:;lllxOkl;,'........,dOOOOOOOOOOOOOOl.........''';:,.............;oxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxxkKWNx::ccc;;cccc;cl;:xkl,,,..........ckOOOOOOOOOOOOx,.........',,:dkl,.'.......':oxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxxkKWNx:cccc;;:lcc::oodkOo;,,...........,xOOOOOOOOOOOOl...........';,:xOxoo;. ...'cdxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxxk0NNd:cccc;;:cccc;cdxOOx;,;'...........'oOOOOOOOOOOOk:............,;,lkOkd:......':oxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxxx0NNx:cccc;,:cccc:;okOOOl,;,.............lOOOOOOOOOOOk;.............;,;dOOko........;oxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxx0NWk::ccc;';ccccc,:xOOOx;,;'.............lOOOOOOOOOOOx;.............';,cOOOkc.......'cxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxxOXWOc:ccc;',ccccc:':kOOOo,;,.............'lOOOOOOOOOOOk:.............';,:xOOOd'......'lxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxxkKWKl:ccc;',:ccccc;.:kOOkc,;'.............'oOOOOOOOOOOOk:..............,;;dOOOdcc:..'.,oxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxx0NNd:ccc:,,;cccccc;.ckOOk:,;'.............,xOOOOOOOOOOOOl..............,;;lOOOdo0Ko,'.,oxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxxOXWOc:cc:,,;:cccccc;':kOOx:;;..............:kOOOOOOOOOOOOd,.............';;lOOOddXXOdl;:oxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxk0NXo:ccc;;;;ccccccc;,:xOOx:;,.............'oOOOOOOOOOOOOOk:.............';;lOOOoxXKkxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxxOXWk::cc;;;;:ccccccc;,;oOOx:,,.............;xOOOOOOOOOOOOOOo'............';;lOOkoOXOxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxx0NXo:cc:;;;;cccccccc;;;ckOk:,,............'oOOOOOOOOOOOOOOOk:............',,lOOdd00kxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxkKW0c:cc:;:;;cccccccc;;:;oOkc,,'...........ckOOOOOxcoxllkOOOOd,...........',;dOkokKkxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxOXWx:ccc;;:;;cccccccc;:c::xOd;,'..........:xOOOOxo:,ox:,lkOOOOo,..........,,ckOdd0Oxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxx0NNo:cc:;::;:ccccccc:;:cc;ckkl,'.........:xOOOOkc,,;oxc,;oOOOOOo,........',;dOddOOxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxk0WKl:cc:;::;:ccccccc:;:ccc;lkxc''......'ckOOOOOkxdlcdkocokOOOOOOd;.......',okxdkOkxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxkKWO::cc:;c:;:ccccccc:;ccccc:lkxc,....':dOOOOOOOOOOOOOOOOOOOOOOOOOkl,....';okxdOOkxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxkXWk::cc::c:;:ccccccc::c:;:cc:lxkxolloxkOkxxkOOOOOOOOOOOOOOOOOOkxkOOkdlcldkkxdOOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxkXWk:ccc::c:;:ccccccc:::,',:cc;cddodxxkkkkxxkOOOOOOOOOOOOOOOOOOkxxkkkxxdddxddkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxkXWk::cc:cc:;:ccccc:;::,.',;::lOOdc,,:ccc:cdkkOkxkkdxkkkdxkxkkkko:ccc;,;okOkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxkXWO::cccccc;;ccc:,;:;;'.,;;;l0KkkOxl:;::;;cc:lc;cl::loc;c::lc:l:,,;;cd0XKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxkKWXl:cccccc:;:c:;,',;,';:c:l0XOxxxkOkdl:,,:::::::::::c:::::;::c;,:dOKK0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxx0NNx:cccccc:,;:::,'''',:c:l0XOxxxxxxkO0klccc:cl;:loloxool;cl::cloOXKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxOXW0c:cccc::c::c::;;,,:c:dKXOxxxxxxxxxxdldxo:ldl:clddddoc:odccdxloxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// dxxxxxxxxxxkKWNd:ccc:lOXx:cc::cc;;ckKKkxxxxxxxxxxxk0KOxolc:,,;:::;'',coxO0Okxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxOXWKl;coOXNWXd:cccc::d0KOxxxxxxxxxxxk0NW0oc:::;'',:c:,''.,:coKWN0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxOXWKOKNXKO0NXxc:clxO0OkxxxxxxxxxxxOXWNOc:cccc:;;;;;,,'',:cc:cOWWKkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxk0KK0Okxxk0XNKO000Oxxxxxxxxxxxxk0NMNxc:c::cc,;llc;;'.'::::c:ckNWXOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxkO00OkxxxxxxxxxxxxxkKWMXd:cc:,,;,':olc;;;,,;:,,:cc:dXWNOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0WWKl:ccc;';;,;,..,:lc;,:c;':ccc:oKWXkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdx0WW0l:ccc;,::,;;'..,cccllc:,;ccc:l0WNOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkKWWKo;;:;;ccc:;,,;:cclccc:;;:;;oKWN0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkKWMNd;:;,;cccccccccccccccc;,;::xNWXkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxONWNOc:c;,;:::::::::::::::::,:c:cON0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOKKOxooolcllllllllllllllllllccllcdkxdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//
//                         ╔═╗╔╦╗╔═╗╦═╗╔╦╗  ╔═╗╔═╗╔╗╔╔╦╗╦═╗╔═╗╔═╗╔╦╗  ╔═╗╦═╗╔═╗╦  ╦╦╔╦╗╔═╗╔╦╗  ╔╗ ╦ ╦
//                         ╚═╗║║║╠═╣╠╦╝ ║   ║  ║ ║║║║ ║ ╠╦╝╠═╣║   ║   ╠═╝╠╦╝║ ║╚╗╔╝║ ║║║╣  ║║  ╠╩╗╚╦╝
//                         ╚═╝╩ ╩╩ ╩╩╚═ ╩   ╚═╝╚═╝╝╚╝ ╩ ╩╚═╩ ╩╚═╝ ╩   ╩  ╩╚═╚═╝ ╚╝ ╩═╩╝╚═╝═╩╝  ╚═╝ ╩ooo
//
//                      ╔╗╔╔═╗╔╦╗╦ ╦╦═╗╔╗ ╔═╗  ╔═╗╦═╗╦ ╦╔═╗╔╦╗╔═╗  ╔═╗╦═╗╔╦╗╦╔═╗╔╦╗╔═╗  ╔═╗╔═╗╔═╗╔╗╔╔═╗╦ ╦
//                      ║║║╠╣  ║ ║ ║╠╦╝╠╩╗║ ║  ║  ╠╦╝╚╦╝╠═╝ ║ ║ ║  ╠═╣╠╦╝ ║ ║╚═╗ ║ ╚═╗  ╠═╣║ ╦║╣ ║║║║  ╚╦╝
//                      ╝╚╝╚   ╩ ╚═╝╩╚═╚═╝╚═╝  ╚═╝╩╚═ ╩ ╩   ╩ ╚═╝  ╩ ╩╩╚═ ╩ ╩╚═╝ ╩ ╚═╝  ╩ ╩╚═╝╚═╝╝╚╝╚═╝ ╩
//
//                                                ╔╗╔╔═╗╔╦╗╦ ╦╦═╗╔╗ ╔═╗   ╦╔═╗
//                                            ─── ║║║╠╣  ║ ║ ║╠╦╝╠╩╗║ ║   ║║ ║ ───
//                                                ╝╚╝╚   ╩ ╚═╝╩╚═╚═╝╚═╝ o ╩╚═╝

pragma solidity 0.8.7;

contract EmptyBunniesRoyalties {
    uint256 private royalties = 0;
    address payable public communityWalletAddress =
        payable(0x89d5BD9687E061f20373b25b87C8a81a61A8DdF6);
    address[] private teamMembers = [
        0x2868A996089EBEe1Ed1D9E56a373398A907c2dA3, //pt
        0x0f97B0Bd7aD496Bc7E0c1d5A6712E9C4796eECb0, //pt
        0x23D4AA98cb89166D8d5043CA6E8d0aE0B7f70495 //frag
    ];
    mapping(address => uint256) private royaltiesShare;

    modifier onlyMaintainer(address sender) {
        require(
            sender == teamMembers[0] || sender == teamMembers[1],
            "Caller must be a maintainer."
        );
        _;
    }

    modifier onlyProjectTeam(address sender) {
        require(
            sender == teamMembers[0] ||
                sender == teamMembers[1] ||
                sender == teamMembers[2],
            "Caller must be a project team member."
        );
        _;
    }

    constructor() payable {}

    fallback() external payable {}

    receive() external payable {}

    function splitRoyalties() public onlyMaintainer(msg.sender) {
        require(address(this).balance > 0, "Balance must be greater than 0");

        uint256 existingRoyalties = 0;
        for (uint256 i = 0; i < teamMembers.length; i++) {
            address member = teamMembers[i];
            existingRoyalties = existingRoyalties + royaltiesShare[member];
        }

        uint256 _unassignedRoyalties = address(this).balance -
            existingRoyalties;

        uint256 share = _unassignedRoyalties / 10;

        uint256 artistShare = share * 5;
        uint256 communityShare = share * 4;
        uint256 projectTeamShare = share / 2;

        royaltiesShare[teamMembers[0]] =
            royaltiesShare[teamMembers[0]] +
            projectTeamShare;
        royaltiesShare[teamMembers[1]] =
            royaltiesShare[teamMembers[1]] +
            projectTeamShare;
        royaltiesShare[teamMembers[2]] =
            royaltiesShare[teamMembers[2]] +
            artistShare;

        (bool success, ) = communityWalletAddress.call{value: communityShare}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function withdrawRoyalties() public onlyProjectTeam(msg.sender) {
        require(
            royaltiesShare[msg.sender] > 0,
            "The address has no project share to withdraw."
        );

        uint256 share = royaltiesShare[msg.sender];

        royaltiesShare[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: share}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() public onlyMaintainer(msg.sender) {
        require(address(this).balance > 0, "Balance must be greater than 0");

        royaltiesShare[teamMembers[0]] = 0;
        royaltiesShare[teamMembers[1]] = 0;
        royaltiesShare[teamMembers[2]] = 0;

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function getShareBalance()
        public
        view
        onlyProjectTeam(msg.sender)
        returns (uint256)
    {
        return royaltiesShare[msg.sender];
    }

    function setCommunityWalletAddress(address payable _communityWalletAddress)
        public
        onlyMaintainer(msg.sender)
    {
        communityWalletAddress = _communityWalletAddress;
    }
}