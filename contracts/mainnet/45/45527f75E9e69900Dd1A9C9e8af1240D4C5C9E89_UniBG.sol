/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

//
//  ʎɹǝllɐ⅁ ɔısɐᙠ lɐsɹǝʌıu∩
//
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface PT {
    function allowance(address _sender, address _spender) external view returns (uint256);
    function burnFrom(address _sender, uint256 _amount) external;
}

interface DT {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

contract UniBG {
    
    address public owner;
    uint256 public activeNFTindex;
    uint256 public lastUpdate;
    uint256 public cost = 24000000000000000000;
    uint256 public tally = 0;

    PT public paymentToken;
    DT public activeNFT;

    event Displaying(address _sender, address _add, uint256 _idx);

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    constructor(PT _paymentToken){
        paymentToken = _paymentToken;
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changePaymentToken(address _newPaymentToken) external onlyOwner {
        paymentToken = PT(_newPaymentToken);
    }

    function updatePrice() external {
        require(block.timestamp - lastUpdate >= 1 days, "price change not due");
        require(cost >= 1000000000000000000, "min cost");
        lastUpdate = block.timestamp;
        cost = cost/2;
    }

    function display(address _add, uint256 _idx) external {        
        uint256 allowance = paymentToken.allowance(msg.sender, address(this));
        require(allowance >= cost, "Allowance is less than cost.");
        paymentToken.burnFrom(msg.sender, cost);
        tally += cost;
        cost += 24000000000000000000;
        lastUpdate = block.timestamp;
        activeNFT = DT(_add);
        activeNFTindex = _idx;
        emit Displaying(msg.sender, _add, _idx);
    }

    function name() public view returns (string memory){
        return activeNFT.name();
    }

    function symbol() public view returns (string memory){
        return activeNFT.symbol();
    }

    function tokenURI(uint256 tokenId) public view returns (string memory){
        return activeNFT.tokenURI(activeNFTindex);
    }

    function ownerOf(uint256 tokenId) public view returns (address){
        return activeNFT.ownerOf(activeNFTindex);
    }

}