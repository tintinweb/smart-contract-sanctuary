// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library TokenData {
function getSVG(string memory message, 
                string memory userName, 
                string memory Id,
                string memory replyMessage) public pure returns(string memory) {
    
    return string(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="600px" height="100px" version="1.1">',
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
        '<text font-size="12" x = "50%" y="60%" id="text" text-anchor="middle" alignment-baseline="middle" class="t" ',
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

function getMetaData(string memory SVG64,
                     string memory userStatus,
                     string memory visibility,
                     string memory timestamp,
                     string memory votesUp,
                     string memory votesDown) public pure returns(string memory) {
    return string(abi.encodePacked('{\n',
        '"description": "NFT-based messaging system.",\n',
        '"image": "', SVG64,'",\n'
        '"background_color": "FFFFFF",\n',
        '"attributes": \n[\n{\n',
            '"trait_type": "User Status",\n',
            '"value": "',userStatus,'"\n},\n{\n',
            '"display_type": "boost_percentage",\n', 
            '"trait_type": "Visibility",\n',
            '"value": ',visibility,'\n},\n{\n',
            '"display_type": "date",\n', 
            '"trait_type": "Created",\n',
            '"value": ',timestamp,'\n},\n{\n',
            '"display_type": "number",\n',
            '"trait_type": "UpVotes",\n',
            '"value": ',votesUp,'\n},\n{\n',
            '"display_type": "number",\n',
            '"trait_type": "DownVotes",\n',
            '"value": ',votesDown,'\n}\n]\n', 
    '}'));
}


}