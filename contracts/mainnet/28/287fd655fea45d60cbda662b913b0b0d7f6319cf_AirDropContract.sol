pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Erc20Token {
    function balanceOf(address _owner) constant public returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
}

contract AirDropContract is Ownable {

    using SafeMath for uint256;

    Erc20Token public tokenRewardContract;

    uint256 public totalAirDropToken;

    address public collectorAddress;

    mapping(address => uint256) public balanceOf;

    event FundTransfer(address backer, uint256 amount, bool isContribution);
    event Additional(uint amount);
    event Burn(uint amount);
    event CollectAirDropTokenBack(address collectorAddress,uint256 airDropTokenNum);

    /**
     * Constructor function
     */
    constructor(
        address _tokenRewardContract,
        address _collectorAddress
    ) public {
        totalAirDropToken = 2e7;
        tokenRewardContract = Erc20Token(_tokenRewardContract);
        collectorAddress = _collectorAddress;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function() payable public {
        require(collectorAddress != 0x0);
        require(totalAirDropToken > 0);

        uint256 ethAmount = msg.value.div(1e18);
        uint256 amount = ethAmount.mul(23000);
        require(amount > 0);

        totalAirDropToken = totalAirDropToken.sub(amount);
        tokenRewardContract.transfer(msg.sender, amount.mul(1e18));

        address wallet = collectorAddress;
        uint256 weiAmount = msg.value;
        wallet.transfer(weiAmount);

        emit FundTransfer(msg.sender, amount, true);
    }

    /**
     *  Add airdrop tokens
     */
    function additional(uint256 amount) public onlyOwner {
        require(amount > 0);

        totalAirDropToken = totalAirDropToken.add(amount);
        emit Additional(amount);
    }

    /**
    *  burn airdrop tokens
    */
    function burn(uint256 amount) public onlyOwner {
        require(amount > 0);

        totalAirDropToken = totalAirDropToken.sub(amount);
        emit Burn(amount);
    }


    /**
     *  The owner of the contract modifies the recovery address of the token
     */
    function modifyCollectorAddress(address newCollectorAddress) public onlyOwner returns (bool) {
        collectorAddress = newCollectorAddress;
    }

    /**
     *  Recovery of remaining tokens
     */
    function collectAirDropTokenBack(uint256 airDropTokenNum) public onlyOwner {
        require(totalAirDropToken > 0);
        require(collectorAddress != 0x0);

        if (airDropTokenNum > 0) {
            tokenRewardContract.transfer(collectorAddress, airDropTokenNum * 1e18);
        } else {
            tokenRewardContract.transfer(collectorAddress, totalAirDropToken * 1e18);
            totalAirDropToken = 0;
        }
        emit CollectAirDropTokenBack(collectorAddress, airDropTokenNum);
    }

    /**
     *  Recovery donated ether
     */
    function collectEtherBack() public onlyOwner {
        uint256 b = address(this).balance;
        require(b > 0);
        require(collectorAddress != 0x0);

        collectorAddress.transfer(b);
    }

    /**
     *  Get the tokenAddress token balance of someone
     */
    function getTokenBalance(address tokenAddress, address who) view public returns (uint){
        Erc20Token t = Erc20Token(tokenAddress);
        return t.balanceOf(who);
    }

    /**
     *  Recycle other ERC20 tokens
     */
    function collectOtherTokens(address tokenContract) onlyOwner public returns (bool) {
        Erc20Token t = Erc20Token(tokenContract);

        uint256 b = t.balanceOf(address(this));
        return t.transfer(collectorAddress, b);
    }

}