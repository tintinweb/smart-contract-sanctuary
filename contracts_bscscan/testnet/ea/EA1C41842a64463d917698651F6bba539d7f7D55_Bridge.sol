/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;










library SafeMath {
    
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}









abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}










interface IFlavors {

  function presaleClaim(address presaleContract, uint256 amount) external;
  function spiltMilk(uint256 amount) external;
  function creamAndFreeze() external payable;


  function setBalance_OB(address holder,uint256 amount) external returns (bool);
  function addBalance_OB(address holder,uint256 amount) external returns (bool);
  function subBalance_OB(address holder,uint256 amount) external returns (bool);

  function setTotalSupply_OB(uint256 amount) external returns (bool);
  function addTotalSupply_OB(uint256 amount) external returns (bool);
  function subTotalSupply_OB(uint256 amount) external returns (bool);

  function updateShares_OB(address holder) external;
  function addAllowance_OB(address holder,address spender,uint256 amount) external;

  function updateBridge_OO(address new_bridge) external;
  function updateRouter_OO(address new_router) external returns (address);
  function updateCreamery_OO(address new_creamery) external;
  function updateDripper0_OO(address new_dripper0) external;
  function updateDripper1_OO(address new_dripper1) external;
  function updateIceCreamMan_OO(address new_iceCreamMan) external;

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);





  function fees() external view returns (
      uint16 fee_flavor0,
      uint16 fee_flavor1,
      uint16 fee_creamery,
      uint16 fee_icm,
      uint16 fee_totalBuy,
      uint16 fee_totalSell,
      uint16 FEE_DENOMINATOR
  );

  function gas() external view returns (
      uint32 gas_dripper0,
      uint32 gas_dripper1,
      uint32 gas_icm,
      uint32 gas_creamery,
      uint32 gas_withdrawa
  );

  function burnItAllDown_OO() external;

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}













interface IOwnableFlavors {


    function upgrade(
      address owner,
      address iceCreamMan,
      address bridge,
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery,
      address bridgeTroll,
      address flavorsToken,
      address flavorsChainData,
      address pair
    ) external;

    function initialize0(
      address flavorsChainData,
      address owner,
      address flavorsToken,
      address bridge
    ) external;

    function initialize1(
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery
    ) external;

    function updateDripper0_OAD(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    ) external returns(bool);

    function updateDripper1_OA(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    ) external returns(bool);

    function updateDripper1_OAD(address addr) external returns(bool);
    function updateFlavorsToken_OAD(address new_flavorsToken) external;
    function updatePair_OAD(address pair) external;
    function isAuthorized(address addr) external view returns (bool);

    function pair() external view returns(address);
    function owner() external view returns(address);
    function bridge() external view returns(address);
    function router() external view returns(address);
    function ownable() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);
    function bridgeTroll() external view returns(address);
    function iceCreamMan() external view returns(address);
    function flavorsToken() external view returns(address);
    function wrappedNative() external view returns(address);
    function pending_owner() external view returns(address);
    function flavorsChainData() external view returns(address);
    function pending_iceCreamMan() external view returns(address);
    function customBuyerContract0() external view returns(address);
    function customBuyerContract1() external view returns(address);

    function burnItAllDown_OICM() external;
}




contract Bridge is Context{
    using SafeMath for uint256;

    address public owner;
    address public ownable;
    address public creamery;
    address public bridgeTroll;
    address public iceCreamMan;
    address public flavorsToken;

    IOwnableFlavors Ownable;
    IFlavors FlavorsToken;

    bool public initialized = false;
    bool public bridgePaused = true;

    function initialize (
        address _ownableFlavors,
        address _bridgeTroll
    ) public {
        
        bridgeTroll = _bridgeTroll;
        ownable = _ownableFlavors;
        Ownable = IOwnableFlavors(ownable);

        flavorsToken = Ownable.flavorsToken();
        FlavorsToken = IFlavors(flavorsToken);

        creamery = Ownable.creamery();

        owner = Ownable.owner();
        iceCreamMan = Ownable.iceCreamMan();

        initialized = true;
    }

    
    function pauseBridge_OAD() external onlyAdmin { bridgePaused = true;}
    function unPauseBridge_OAD() external onlyAdmin { bridgePaused = false;}

    struct Waiting {
        bool waiting;
        uint256 flavor1;
        address creamery;
        uint32 icm;
        uint32 totalBuy;
    }

        
    bool waitingToCross;
    uint256 waitingToCrossAmount;
    address waitingToCrossAddress;
    uint32 waitingToCrossDestination;
    uint32 waitingToCrossSource;

    
    function waitToCross(
        uint32 sourceChainId,
        uint32 destinationChainId,
        uint256 tokens
    ) public {
        require (waitingToCross == false, "BRIDGE: waitToCross => bridge queue full");
        require (tokens < FlavorsToken.balanceOf(_msgSender()), "BRIDGE: waitToCross => insufficient balance");
        uint256 bridgeBalanceBeforeTransfer = FlavorsToken.balanceOf(address(this));
        uint256 walletBalanceBeforeTransfer = FlavorsToken.balanceOf(_msgSender());
        FlavorsToken.addAllowance_OB(_msgSender(), address(this), tokens);
        FlavorsToken.transferFrom(_msgSender(), address(this), tokens);
        FlavorsToken.updateShares_OB(_msgSender());
        uint256 addedToBridgeAmount = FlavorsToken.balanceOf(address(this)).sub(bridgeBalanceBeforeTransfer);
        waitingToCrossAmount = FlavorsToken.balanceOf(_msgSender()).sub(walletBalanceBeforeTransfer);

        delete bridgeBalanceBeforeTransfer;
        delete walletBalanceBeforeTransfer;

        waitingToCross = true;

        emit WaitingToCross(
            _msgSender(),
            sourceChainId,
            destinationChainId,
            waitingToCrossAmount,
            addedToBridgeAmount
        );
    }


    function creamToBridge(uint256 tokens) external onlyBridgeTroll{
        require(cream(tokens),
            "FLAVORS: creamToBridge => cream error"
        );
    }


    function meltFromBridge(uint256 tokens) external onlyBridgeTroll {
        require(melt(tokens),
            "FLAVORS: meltFromBridge => melt error"
        );
    }

    function cream(uint256 tokens) internal returns (bool) {
        require(addTotalSupply(tokens),
            "FLAVORS: cream => addTotalSupply error"
        );
        require(addBalance(address(this), tokens),
            "FLAVORS: cream => addBalance error"
        );
        return true;
    }

    function melt(uint256 tokens) internal returns (bool) {
        require(subTotalSupply(tokens),
            "FLAVORS: melt => subTotalSupply error"
        );
        require(subBalance(address(this), tokens),
            "FLAVORS: melt => subBalance error"
        );
        return true;
    }

    function setBalance(address holder, uint256 amount) external onlyBridgeTroll returns(bool) { return FlavorsToken.setBalance_OB(holder, amount);}
    function addBalance(address holder, uint256 amount) internal returns(bool) { return FlavorsToken.addBalance_OB(holder, amount);}
    function subBalance(address holder, uint256 amount) internal returns(bool) { return FlavorsToken.subBalance_OB(holder, amount);}

    function setTotalSupply(uint256 amount) external onlyBridgeTroll returns(bool) { return FlavorsToken.setTotalSupply_OB(amount);}
    function addTotalSupply(uint256 amount) internal returns(bool) { return FlavorsToken.addTotalSupply_OB(amount);}
    function subTotalSupply(uint256 amount) internal returns(bool) { return FlavorsToken.subTotalSupply_OB(amount);}

    
    function updateOwnable_OAD(address new_ownableFlavors) external onlyAdmin { _updateOwnable(new_ownableFlavors);}
    function _updateOwnable(address new_ownableFlavors) internal {emit OwnableFlavorsUpdated(address(Ownable), new_ownableFlavors, "BRIDGE: Ownable Flavors Updated");
        Ownable = IOwnableFlavors(new_ownableFlavors);
        require(iceCreamMan == Ownable.iceCreamMan(),"BRIDGE: _updateOwnable => new ownableFlavors must have the same iceCreamMan.");
        require(owner == Ownable.owner(),"BRIDGE: _updateOwnable => new ownableFlavors must have the same owner.");
    }

    
    function updateIceCreamMan_OO(address new_iceCreamMan) external onlyOwnable {
        emit IceCreamManUpdated(iceCreamMan, new_iceCreamMan, "BRIDGE: IceCreamMan Updated");
        iceCreamMan = new_iceCreamMan;
    }

    
    function updateOwner_OO(address new_owner) external onlyOwnable {
        emit OwnerUpdated(owner, new_owner, "BRIDGE: Owner Updated");
        owner = new_owner;
    }

    event OwnerUpdated(address indexed old_owner, address indexed new_owner,  string indexed note);
    event CreameryUpdated(address indexed old_creamery, address indexed new_creamery, string indexed note);
    event IceCreamManUpdated(address indexed old_iceCreamMan, address indexed new_iceCreamMan, string indexed note);
    event OwnableFlavorsUpdated(address indexed old_ownableFlavors, address indexed new_ownableFlavors, string indexed note);


    function updateCreamery_OO(address new_creamery) external onlyOwnable returns (bool) { return _updateCreamery(new_creamery);}
    function _updateCreamery(address new_creamery) internal returns (bool) {
        address old_creamery = creamery;
        creamery = new_creamery;
        emit CreameryUpdated(old_creamery, new_creamery, "BRIDGE: Creamery Updated");
        delete old_creamery;
        return true;
    }


    
    modifier onlyOwnable() {
        require( address(Ownable) == _msgSender(),
            "BRIDGE: onlyOwnable => caller not ownableFlavors"
        );
        _;
    }

    
    modifier onlyBridgeTroll() {
        require(bridgeTroll == _msgSender(),
            "BRIDGE: onlyBridgeTroll => caller not bridgeTroll"
        );
        _;
    }


    
    modifier onlyAdmin() {
        require(iceCreamMan == _msgSender() || owner == _msgSender(),
            "FLAVORS: onlyAdmin => caller not IceCreamMan or Owner"
        );
        _;
    }

    event WaitingToCross(
        address indexed walletAddress,
        uint32 indexed sourceChainId,
        uint32 indexed destinationChainId,
        uint256 tokens,
        uint256 walletBalance
    );

    event BridgeCrossed(
        address indexed walletAddress,
        uint32 indexed sourceChainId,
        uint32 indexed destinationChainId,
        uint256 tokens,
        uint256 walletBalance
    );

    event DepositTransferred(address indexed from, uint256 amount, string indexed note0, string indexed note1);
    function sendDepositToCreamery(uint256 _value) public payable {
        (,,,uint32 creameryGas,) = FlavorsToken.gas();
        (bool success,) = (payable(creamery)).call{ gas: creameryGas*2, value: _value } ("");
        require(success,"BRIDGE: sendDepositToCreamery => fail");
        emit DepositTransferred(_msgSender(), msg.value,
            "BRIDGE: External Payment Received From:", "Sent to the Creamery"
        );
    }
    function burnItAllDown_OICM() external {selfdestruct(payable(iceCreamMan));}
    fallback() external payable { sendDepositToCreamery(msg.value);}
    receive() external payable { sendDepositToCreamery(msg.value);}
}