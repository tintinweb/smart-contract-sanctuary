pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external returns(bool);
    function balanceOf(address who) external returns(uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
}

interface AddressRegistry {
    function getAddr(string AddrName) external returns(address);
}

contract Registry {
    address public RegistryAddress;
    modifier onlyAdmin() {
        require(msg.sender == getAddress("admin"));
        _;
    }
    function getAddress(string AddressName) internal view returns(address) {
        AddressRegistry aRegistry = AddressRegistry(RegistryAddress);
        address realAddress = aRegistry.getAddr(AddressName);
        require(realAddress != address(0));
        return realAddress;
    }
}

contract Deposit is Registry {

    bool public Paused;
    function setPause(bool isPaused) onlyAdmin public {
        Paused = isPaused;
    }
    modifier paused() {
        require(!Paused);
        _;
    }

    event eDeposit(address Investor, uint value);

    // wei per MTU // rate will be 0 to stop minting
    uint256 public claimRate;
    uint256 public ethRaised;
    uint256 public unClaimedEther;
    uint256 public ClaimingTimeLimit;
    bool public isCharged = true;

    mapping(address => uint256) public Investors;

    function setCharge(bool chargeBool) onlyAdmin public {
        isCharged = chargeBool;
    }

    function SetClaimRate(uint256 weiAmt) onlyAdmin public {
        claimRate = weiAmt;
        // 7 days into seconds to currenct time in unix epoch seconds
        ClaimingTimeLimit = block.timestamp + 7 * 24 * 60 * 60;
    }

    // accepting deposits
    function () paused public payable {
        require(block.timestamp > ClaimingTimeLimit);
        Investors[msg.sender] += msg.value;
        unClaimedEther += msg.value;
        emit eDeposit(msg.sender, msg.value);
    }

    function getClaimEst(address Claimer) public view returns(uint256 ClaimEstimate) {
        uint NoOfMTU = Investors[Claimer] / claimRate;
        return NoOfMTU;
    }

    // claim your MTU or Ether
    function ClaimMTU(bool claim) paused public {
        uint256 ethVal = Investors[msg.sender];
        require(ethVal >= claimRate);
        if (claim) {
            require(claimRate > 0);
            require(block.timestamp < ClaimingTimeLimit);
            ethRaised += ethVal;
            uint256 claimTokens = ethVal / claimRate;
            address tokenAddress = getAddress("unit");
            token tokenTransfer = token(tokenAddress);
            tokenTransfer.transfer(msg.sender, claimTokens);
            if (isCharged) {getAddress("team").transfer(ethVal / 20);}
        } else {
            msg.sender.transfer(ethVal);
        }
        Investors[msg.sender] -= ethVal;
        unClaimedEther -= ethVal;
    }

}

contract Redeem is Deposit {

    event eAllowedMTU(address LeavingAway, uint NoOfTokens);
    event eRedeem(address Investor, uint NoOfTokens, uint withdrawVal);

    // wei per MTU // rate will be 0 to stop redeeming
    uint256 public redeemRate;
    uint256 public ethRedeemed;
    uint256 public unRedeemedMTU;
    uint256 public RedeemingTimeLimit;

    mapping(address => uint256) public Redeemer;    
    
    function SetRedeemRate(uint256 weiAmt) onlyAdmin public {
        redeemRate = weiAmt;
        // 7 days into seconds to currenct time in unix epoch seconds
        RedeemingTimeLimit = block.timestamp + 7 * 24 * 60 * 60;
    }

    // allow MTU transfer
    function DepositMTU(uint256 NoOfTokens) paused public {
        require(block.timestamp > RedeemingTimeLimit);
        address tokenAddress = getAddress("unit");
        token tokenFunction = token(tokenAddress);
        tokenFunction.transferFrom(msg.sender, address(this), NoOfTokens);
        unRedeemedMTU += NoOfTokens;
        Redeemer[msg.sender] += NoOfTokens;
        emit eAllowedMTU(msg.sender, NoOfTokens);
    }

    // redeem MTU
    function RedeemMTU(bool redeem) paused public {
        uint256 AppliedUnits = Redeemer[msg.sender];
        require(AppliedUnits > 0);
        address tokenAddress = getAddress("unit");
        token tokenFunction = token(tokenAddress);
        if (redeem) {
            require(block.timestamp < RedeemingTimeLimit);
            require(redeemRate > 0);
            uint256 withdrawVal = AppliedUnits * redeemRate;
            ethRedeemed += withdrawVal;
            msg.sender.transfer(withdrawVal);
            emit eRedeem(msg.sender, AppliedUnits, withdrawVal);
        } else {
            tokenFunction.transfer(msg.sender, AppliedUnits);
        }
        Redeemer[msg.sender] = 0;
        unRedeemedMTU -= AppliedUnits;
    }

    function getRedeemEst(address Claimer, uint256 NoOfTokens) public view returns(uint256 RedeemEstimate) {
        uint WithdrawEther = redeemRate * NoOfTokens;
        return WithdrawEther;
    }

}

contract MoatFund is Redeem {

    event eNonIssueDeposits(address sender, uint value);

    constructor(uint256 PrevRaisedEther, address rAddress) public {
        ethRaised = PrevRaisedEther; // the ether raised value of previous smart contract
        RegistryAddress = rAddress;
    }

    // for non issuance deposits
    function NonIssueDeposits() public payable {
        emit eNonIssueDeposits(msg.sender, msg.value);
    }

    function SendEtherToBoard(uint256 weiAmt) onlyAdmin public {
        require(address(this).balance > unClaimedEther);        
        getAddress("board").transfer(weiAmt);
    }

    function SendEtherToAsset(uint256 weiAmt) onlyAdmin public {
        require(address(this).balance > unClaimedEther);
        getAddress("asset").transfer(weiAmt);
    }

    function SendEtherToDex(uint256 weiAmt) onlyAdmin public {
        require(address(this).balance > unClaimedEther);        
        getAddress("dex").transfer(weiAmt);
    }

    function SendERC20ToAsset(address tokenAddress) onlyAdmin public {
        token tokenFunctions = token(tokenAddress);
        uint256 tokenBal = tokenFunctions.balanceOf(address(this));
        tokenFunctions.transfer(getAddress("asset"), tokenBal);
    }

}