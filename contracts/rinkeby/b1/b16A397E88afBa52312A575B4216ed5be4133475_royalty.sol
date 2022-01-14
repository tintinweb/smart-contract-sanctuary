// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract royalty {
    
    uint shareOfRoyalty1 = 9800;
    uint shareOfRoyalty2 = 100;
    uint shareOfRoyalty3 = 100;

    address addr1 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address addr2 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    address addr3 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

    receive() external payable {}

    function clame() external payable {
        uint total = address(this).balance;
        require(msg.sender == addr1 || msg.sender == addr2 || msg.sender == addr3,
            "no permission address");
       
        (bool sent, ) = addr1.call{value: (total*shareOfRoyalty1/10000)}("");
        require(sent, "Failed to send to address 1 ");
        (sent, ) = addr2.call{value: (total*shareOfRoyalty2/10000)}("");
        require(sent, "Failed to send to address 1");
        (sent, ) = addr3.call{value: (total*shareOfRoyalty3/10000)}("");
        require(sent, "Failed to send to address 1");
    }
}