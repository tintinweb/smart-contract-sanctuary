// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./context.sol";
import './safeMath.sol';
import './IERC20.sol';

contract Privatesale is Ownable {
    using SafeMath for uint256;

    // A participant in the privatesale
    struct Participant {
        // The amount someone can buy
        uint256 maxPurchaseAmountInBNB;
        // How much he already bought
        uint256 alreadyPurcheasedInBNB;

        uint256 fipiTokenPurcheased;

        uint256 fipiTokenClaimed;

        uint256 releasesClaimed;
    }

    event Bought(address indexed account, uint256 indexed amount);
    event Claimed(address indexed account, uint256 indexed amount);

    uint256 public tokenBNBRatio; //how much tokens for one bnb
    address payable public _BNBReciever;

    uint256 public tolalTokenSold; 
    uint256 public tolalBNBRaised; 
    uint256 public hardCap; 
    
    //uint256[] internal releaseDates = [1646136000,1648814400,1651406400,1654084800,1656676800];
    uint256[] internal releaseDates = [1641078000,1641078900,1641079800,1641080700,1641081540];
    address payable public _BurnWallet = payable(0x000000000000000000000000000000000000dEaD);

    IERC20 public binanceCoin;
    IERC20 public fiPiToken;


    mapping(address => Participant) private participants;

    function addParticipant(address user, uint256 maxPurchaseAmount) external onlyOwner {
        require(user != address(0));
        participants[user].maxPurchaseAmountInBNB = maxPurchaseAmount;
    }

    function revokeParticipant(address user) external onlyOwner {
        require(user != address(0));
        participants[user].maxPurchaseAmountInBNB = 0;
    }

    function nextReleaseIn() external view returns (uint256){
        for (uint256 i = 0; i < releaseDates.length; i++) 
        {
            if (releaseDates[i] >= block.timestamp) 
            {
               return releaseDates[i];
            }
        }
        return 0;
    }

    //0xc41359a5f17D497D0cfc888D86f6EC9b0396187F
    constructor(IERC20 _fipiToken) public {

        _BNBReciever = payable(_msgSender());
        tokenBNBRatio = 10500;
        fiPiToken = _fipiToken;
        hardCap = 2 * 10 ** 18; //hardcap 200 BNB IN WEI
    } 

    function claim() public
    {
        require(msg.sender != address(0));
        Participant storage participant = participants[msg.sender];

        require(participant.fipiTokenPurcheased > 0, "You did not bought anything!");

        uint256 unlockedReleasesCount = 0;

        for (uint256 i = 0; i < releaseDates.length; i++) 
        {
            if (releaseDates[i] <= block.timestamp) 
            {
               unlockedReleasesCount ++;
            }
        }

        require(unlockedReleasesCount > participant.releasesClaimed, "You have already claimed all currently unlocked releases!");
        uint256 allTokenstReleasedToParticipant = participant.fipiTokenPurcheased.mul(unlockedReleasesCount).div(5);
        uint256 tokenToBeSendNow = allTokenstReleasedToParticipant.sub(participant.fipiTokenClaimed);
        fiPiToken.transfer(msg.sender, tokenToBeSendNow);
        participant.fipiTokenClaimed = allTokenstReleasedToParticipant;
        participant.releasesClaimed = unlockedReleasesCount;


        emit Claimed(msg.sender, tokenToBeSendNow);

    }

    function buy() payable public 
    {
        uint256 amountTobuy = msg.value;
        require(amountTobuy > 0, "You need to send some BNB");
        require(tolalBNBRaised.add(amountTobuy) <= hardCap, "Hardcap exceeded");


        require(msg.sender != address(0));
        Participant storage participant = participants[msg.sender];
        require(participant.maxPurchaseAmountInBNB > 0, "You are not on whitelist");
        require(participant.alreadyPurcheasedInBNB.add(amountTobuy) <= participant.maxPurchaseAmountInBNB, "You already bought your limit");
        
        uint256 numTokens = amountTobuy.div(10 ** 9).mul(tokenBNBRatio);
       
        tolalTokenSold = tolalTokenSold.add(numTokens);
        tolalBNBRaised = tolalBNBRaised.add(amountTobuy);
        participant.alreadyPurcheasedInBNB = participant.alreadyPurcheasedInBNB.add(amountTobuy);
        participant.fipiTokenPurcheased = participant.fipiTokenPurcheased.add(numTokens);

        emit Bought(msg.sender, msg.value);
    }   

    function isWhitelisted(address account) external view returns (bool){
        Participant storage participant = participants[account];
        return participant.maxPurchaseAmountInBNB > 0;
    }

    function bnbInPrivateSaleSpend(address account) external view returns (uint256){
        Participant storage participant = participants[account];
        return participant.alreadyPurcheasedInBNB;
    }

    function yourFiPiTokens(address account) external view returns (uint256){
        Participant storage participant = participants[account];
        return participant.fipiTokenPurcheased;
    }


    function burnLeftTokens() external onlyOwner {
        fiPiToken.transfer(_BurnWallet, fiPiToken.balanceOf(address(this)));
    }
    
    function withDrawBNB() public {
        require(_msgSender() == _BNBReciever, "Only the bnb reciever can use this function!");
        _BNBReciever.transfer(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}