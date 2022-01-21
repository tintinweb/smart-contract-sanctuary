// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library NFtalkMetaData {
function getSVG(string memory message, 
                string memory userName, 
                string memory Id,
                string memory replyMessage) public pure returns(string memory) {
    
    return string(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="600px" height="100px" version="1.1" style="background-color:white">',
        '<style>'
        '.t { font-family: monospace; -webkit-user-select: none; -moz-user-select: none;-ms-user-select: none;user-select: none; }',
        '</style>',
        '<rect x="0" y="0" width="100%" height="100%" rx="15" ry="15" stroke="black" fill="white" />',
        message,
        '<text font-size="14" x = "2%" y="20%" id="head"  class="t"> ',
        userName,
        ':</text>',
        replyMessage,
        '<text font-size="10" x = "2%" y="90%" id="num"  class="t">',
        '#', Id,
        '</text>',
        '</svg>'
    ));
}

function getMessageCode(string memory message, string memory visibility) public pure returns(string memory) {
    return string(abi.encodePacked(
        '<text font-size="12" x = "50%" y="55%" id="text" text-anchor="middle" dominant-baseline="middle" class="t" ',
        'opacity="',visibility,'%">',
        message,
        '</text>'
    ));
}

function getReplyCode(string memory replyUserName, string memory replyId) public pure returns(string memory) {
    return string(abi.encodePacked(
            '<text font-size="12" x = "2%" y="36%" id="reply"  class="t">',
            '@',replyUserName,' #',replyId,
            '</text>'
        ));
}

function getTokenMetaData(string memory SVG64,
                     string memory userStatus,
                     string memory visibility,
                     string memory timestamp,
                     string memory votesUp,
                     string memory votesDown) public pure returns(bytes memory) {
    return bytes(abi.encodePacked('{',
        '"description": "",',
        '"image": "', SVG64,'",'
        '"background_color": "FFFFFF",',
        '"attributes": [{',
            '"trait_type": "User Status",',
            '"value": "',userStatus,'"},{',
            '"display_type": "boost_percentage",', 
            '"trait_type": "Visibility",',
            '"value": ',visibility,'},{',
            '"display_type": "date",', 
            '"trait_type": "Created",',
            '"value": ',timestamp,'},{',
            '"display_type": "number",',
            '"trait_type": "UpVotes",',
            '"value": ',votesUp,'},{',
            '"display_type": "number",',
            '"trait_type": "DownVotes",',
            '"value": ',votesDown,'}]', 
    '}'));
}

function getContractMetaData(string memory SVGImage, string memory SVGMedia) public pure returns(bytes memory) {
    return bytes(abi.encodePacked('{',
        '"name": "NFtalk",',
        '"description": "NFtalk message.',
        'Each message (85 chars max) is minted as a new NFT. ',
        'Reply and react to other messages and set your user name. ',
        'You are the only one who can transfer or burn your messages. ',
        'Their content, however, may fade into invisibility based on community governance. ',
        'NFtalk allows you to communicate without having to rely on a centralized platform. ',
        'It is not a means of spreading content that is rightfully removed from other platforms.",',
        '"symbol": "NFtalk",'
        '"image": "',SVGImage,'",',
        '"media": [{',
        '"type": "unknown",',
        '"value": "',SVGMedia,'"',
        '}]',
    '}'));
}

function getSVGContractImage() public pure returns(string memory) {
    return string(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" version="1.1"  style="background-color:white">',
        '<style>',
        '.t { font-family: monospace; -webkit-user-select: none; -moz-user-select: none;-ms-user-select: none;user-select: none; }',
        '</style>',
        '<text font-size="20" x = "50%" y="50%" id="text" text-anchor="middle" dominant-baseline="middle" class="t">NFtalk</text>',
        '</svg>'
    ));
}

function getSVGContractMedia() public pure returns(string memory) {
    return string(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="200" version="1.1"  style="background-color:white">',
        '<style>',
        '.t { font-family: monospace; -webkit-user-select: none; -moz-user-select: none;-ms-user-select: none;user-select: none; }',
        '</style>',
        '<text font-size="20" x = "5%" y="50%" id="text" dominant-baseline="middle" class="t">#NFtalk. The decentralized messaging system.</text>',
        '</svg>'
    ));
}

}