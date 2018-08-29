pragma solidity 0.4.24;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



////////////////////////////////////////////////////////
//:                                                  ://
//:          SpaceImpulse Public Engagement          ://
//:..................................................://
////////////////////////////////////////////////////////




contract TokenCHK {

  function balanceOf(address _owner) public pure returns (uint256 balance) {}
  function transfer(address to, uint256 value) public returns (bool);
}




contract SpaceImpulse is Ownable {

    using SafeMath for uint256;

    string public name = "SpaceImpulse Public Engagement";      // Extended name of this contract
    uint256 public tokenPrice;            // Set the fixed SpaceImpulse token price
    uint256 public maxCap = 0;            // Set the target maximum cap in ETH
    address public FWDaddrETH;            // Set the address to forward the received ETH to
    address public SpaceImpulseERC20;     // Set the SpaceImpulse ERC20 contract address
    uint256 public totalSold;             // Keep track of the contributions total
    uint256 public minPersonalCap;        // Set the minimal cap in ETH
    uint256 public decimals = 18;         // The decimals to consider

    mapping (address => uint256) public sold;         // Map the SpaceImpulse token allcations

    uint256 public pubEnd;                            // Set the unixtime END for the public engagement
    address contractAddr = this;                      // Better way to point to this from this

    // Constant to simplify the conversion of token amounts into integer form
    uint256 public tokenUnit = uint256(10)**decimals;



    //
    // "toETHaddr" is the address to which the ETH contributions are forwarded to, aka FWDaddrETH
    // "SpaceImpulseERC20" is the address of the SpaceImpulseERC20 token contract.
    //
    // NOTE: this contract will sell only its token balance on the ERC20 specified in SpaceImpulseERC20
    //       the maxCap in ETH and the tokenPrice will indirectly set the SpaceImpulse token amount on sale
    //
    // NOTE: this contract should have sufficient SpaceImpulse token balance to be > maxCap / tokenPrice
    //
    // NOTE: this contract will stop REGARDLESS of the above (maxCap) when its token balance is all sold
    //
    // The Owner of this contract can set: Price, End, MaxCap, SpaceImpulseERC20 and ETH Forward address
    //
    // The received ETH are directly forwarded to the external FWDaddrETH address
    // The SpaceImpulse tokens are transferred to the contributing addresses once withdrawPUB is executed
    //


    constructor
        (
        address SpaceImpulse_ERC20
        ) public {
        FWDaddrETH = 0x69587ed6f526f8B3FD9eB01d4F1FCC86f0394c8f;
        SpaceImpulseERC20 = SpaceImpulse_ERC20;
        tokenPrice = 150000000000000;
        minPersonalCap = 150000000000000000;
        pubEnd = 1540987140;

    }

    function () public payable {
        buy();               // Allow to buy tokens sending ETH directly to the contract, fallback
    }

    function setFWDaddrETH(address _value) public onlyOwner {
      FWDaddrETH = _value;     // Set the forward address default toETHaddr

    }


    function setSpaceImpulse(address _value) public onlyOwner {
      SpaceImpulseERC20 = _value;     // Set the SpaceImpulseERC20 contract address

    }


    function setMaxCap(uint256 _value) public onlyOwner {
      maxCap = _value;         // Set the max cap in ETH default 0

    }


    function setPrice(uint256 _value) public onlyOwner {
      tokenPrice = _value;     // Set the token price default 0

    }


    function setPubEnd(uint256 _value) public onlyOwner {
      pubEnd = _value;         // Set the END of the public engagement unixtime default 0

    }

    function setMinPersonalCap(uint256 _value) public onlyOwner {
      minPersonalCap = _value;  // Set min amount to buy
    }



    function buy() public payable {

        require(block.timestamp < pubEnd);          // Require the current unixtime to be lower than the END unixtime
        require(msg.value > 0);                     // Require the sender to send an ETH tx higher than 0
        require(msg.value <= msg.sender.balance + msg.value);   // Require the sender to have sufficient ETH balance for the tx
        require(msg.value >= minPersonalCap);        // Require sender eth amount be higher than minPersonalCap

        // Requiring this to avoid going out of tokens, aka we are getting just true/false from the transfer call
        require(msg.value + totalSold <= maxCap);

        // Calculate the amount of tokens per contribution
        uint256 tokenAmount = (msg.value * tokenUnit) / tokenPrice;

        // Requiring sufficient token balance on this contract to accept the tx
        require(tokenAmount + ((totalSold * tokenUnit) / tokenPrice)<=TokenCHK(SpaceImpulseERC20).balanceOf(contractAddr));

        transferBuy(msg.sender, tokenAmount);       // Instruct the accounting function
        totalSold = totalSold.add(msg.value);       // Account for the total contributed/sold
        FWDaddrETH.transfer(msg.value);             // Forward the ETH received to the external address

    }




    function withdrawPUB() public returns(bool){

        require(block.timestamp > pubEnd);          // Require the SpaceImpulse to be over - actual time higher than end unixtime
        require(sold[msg.sender] > 0);              // Require the SpaceImpulseERC20 token balance to be sent to be higher than 0

        // Send SpaceImpulseERC20 tokens to the contributors proportionally to their contribution/s
        if(!SpaceImpulseERC20.call(bytes4(keccak256("transfer(address,uint256)")), msg.sender, sold[msg.sender])){revert();}

        delete sold[msg.sender];
        return true;

    }




    function transferBuy(address _to, uint256 _value) internal returns (bool) {

        require(_to != address(0));                 // Require the destination address being non-zero

        sold[_to] = sold[_to].add(_value);            // Account for multiple txs from the same address

        return true;

    }



        //
        // Probably the sky would fall down first but, in case skynet feels funny..
        // ..we try to make sure anyway that no ETH would get stuck in this contract
        //
    function EMGwithdraw(uint256 weiValue) external onlyOwner {
        require(block.timestamp > pubEnd);          // Require the public engagement to be over
        require(weiValue > 0);                      // Require a non-zero value

        FWDaddrETH.transfer(weiValue);              // Transfer to the external ETH forward address
    }

    function sweep(address _token, uint256 _amount) public onlyOwner {
        TokenCHK token = TokenCHK(_token);

        if(!token.transfer(owner, _amount)) {
            revert();
        }
    }

}