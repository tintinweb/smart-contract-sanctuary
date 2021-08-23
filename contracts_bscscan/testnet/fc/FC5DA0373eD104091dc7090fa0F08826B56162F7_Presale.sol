pragma solidity >=0.6.12;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pregalaxy.sol";
contract Presale is Ownable {
    using SafeMath for uint256;

    event PresaleParticipated(address indexed participant, uint256 tokenBought);
    event PresaleLiquidityWithdrawed(address indexed withdrawer, uint256 bnbAmount);


    uint256 public MAXIMUM_PRESALE_AMOUNT;
    string public PRESALE_TOKEN_NAME;
    PreGalaxy public PRESALE_TOKEN;
    uint256 public PRESALE_TOKEN_PRICE; // how much token you get for a 1 BNB == 35000
    uint public PRESALE_START_BLOCK;
    uint public PRESALE_END_BLOCK;
    uint256 public CURRENT_PRESALE_AMOUNT = 0;
    address public deadAddr = 0x000000000000000000000000000000000000dEaD;
    constructor(
        string memory token_name,
        PreGalaxy presale_token,
        uint256 max_token,
        uint256 price,
        uint start_block,
        uint end_block
    ) public {
        MAXIMUM_PRESALE_AMOUNT = max_token;
        PRESALE_TOKEN_NAME = token_name;
        PRESALE_TOKEN = presale_token;
        PRESALE_TOKEN_PRICE = price;
        PRESALE_START_BLOCK = start_block;
        PRESALE_END_BLOCK = end_block;
    }

    function endPresale(address dest) public onlyOwner {
        require(block.number >= PRESALE_END_BLOCK, "Presale didnt end yet.");
        // No one can withdraw bnb balance before presale ends.
        uint256 bnb_balance = address(this).balance;
        msg.sender.transfer(bnb_balance); 
        uint256 contractBalance = PRESALE_TOKEN.balanceOf(address(this));
        PRESALE_TOKEN.transfer(deadAddr, contractBalance); // burns existing Presale tokens to prevent from swapping
        // sends bnb balance to the admin account to initiate the liquidity and create farm token.
        emit PresaleLiquidityWithdrawed(dest, bnb_balance);
    }

    function enterPresale() public payable {
        // presale participate function. It automatically takes the bnb and sends 
        // the equivalent amount of presale token to the address
        require(block.number >= PRESALE_START_BLOCK,"Presale didnt started yet.");
        require(block.number <= PRESALE_END_BLOCK,"Presale is done.");
        require(msg.sender != address(0),"Address zero participant");
        require(msg.value >= 0.01 ether,"Min 0.01 bnb to enter presale.");
        uint bnb_sent = msg.value; //değiştim
        address participant = msg.sender;
        uint256 token_amount = bnb_sent.mul(PRESALE_TOKEN_PRICE);
        require(CURRENT_PRESALE_AMOUNT.add(token_amount) <= MAXIMUM_PRESALE_AMOUNT,"Presale max amount exceeds.");
        uint256 tokenBal = PRESALE_TOKEN.balanceOf(address(this));
        require(tokenBal >= token_amount, "Token amount exceeds.");
        CURRENT_PRESALE_AMOUNT = CURRENT_PRESALE_AMOUNT.add(token_amount);
        PRESALE_TOKEN.transfer(msg.sender, token_amount);
        emit PresaleParticipated(participant, bnb_sent);
    }

    function presaleTokensLeft() public view returns(uint256) {
        return PRESALE_TOKEN.balanceOf(address(this));
    }

    function presaleTokenPercentage() public view returns(uint256) {
        uint256 bought = MAXIMUM_PRESALE_AMOUNT.sub(PRESALE_TOKEN.balanceOf(address(this)));
        return bought.div(MAXIMUM_PRESALE_AMOUNT).mul(100); // returns percentage
    }

    function presaleBlocksLeft() public view returns(uint256) {
        if(PRESALE_END_BLOCK > block.number) {
            return PRESALE_END_BLOCK.sub(block.number);
        } else {
            return 0;
        }
    }

    function presaleStartBlockLeft() public view returns(uint256) {
        uint256 current_block = block.number;
        if(PRESALE_START_BLOCK < current_block) {
            return current_block.sub(PRESALE_START_BLOCK);
        } else {
            return 0;
        }
    }

    function presaleBNBAmount() public view returns(uint256) {
        return address(this).balance;
    }
}