pragma solidity ^0.8.0;
import "./Clocks.sol";
import "./SafeMath.sol";
import "./erc721.sol";
import "./ownable.sol";
import "./ClocksRedemption.sol";
contract Exchange is Ownable {
    using SafeMath for uint256;
    string public name = "CLOCKS Exchange";
    CLOCKS public clocks;
    TheInfinityCollections public collections;
    ClocksRedemption public redemption;
    bool redemptionSet = false;

    event ClocksRedeemed(address account,uint amount);
    event ClocksClaimed(address account,uint amount);

    // Mapping from token ID to owner address
    mapping(address => bool) private claimed;

    constructor(CLOCKS _clocks, TheInfinityCollections _collections) public {
        clocks = _clocks;
        collections = _collections;
    }

    function claim() public {
        require(collections.mintCredits(msg.sender) > 0, "You have no credits to claim");
        require(claimed[msg.sender] != true, "You have already claimed your credits");
        uint256 amount = collections.mintCredits(msg.sender) * (10**18);
        amount = amount / uint256(10);
        clocks.transfer(msg.sender,amount);
        claimed[msg.sender] = true;
        emit ClocksClaimed(msg.sender, amount);
    }

    function redeem(uint clocks_amount) public {
        uint256 divisor = 1 * 10 ** 18;
        require(redemptionSet == true, "Owner Needs to Set Redemption Address");
        require(clocks.balanceOf(msg.sender) >= clocks_amount, "Trying to burn more tokens than you own");
        require(clocks_amount >= divisor, "Amount to redeem must be greater than or equal to 1");
        require(clocks_amount % divisor == 0, "Need to enter whole number");
        clocks.burnFrom(msg.sender,clocks_amount);
        uint256 amount = clocks_amount / divisor;
        redemption.redeem(msg.sender,amount);
        emit ClocksRedeemed(msg.sender, clocks_amount);
    }

    function setRedemptionAddress(ClocksRedemption _redemption) public onlyOwner returns(bool){
        redemption = _redemption;
        redemptionSet = true;
        return redemptionSet;
    }


    

}