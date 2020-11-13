pragma solidity 0.6.0;

/**
 * @title Price contract
 * @dev Price check and call
 */
contract Nest_3_OfferPrice{
    using SafeMath for uint256;
    using address_make_payable for address;
    using SafeERC20 for ERC20;
    
    Nest_3_VoteFactory _voteFactory;                                //  Voting contract
    ERC20 _nestToken;                                               //  NestToken
    Nest_NToken_TokenMapping _tokenMapping;                         //  NToken mapping
    Nest_3_OfferMain _offerMain;                                    //  Offering main contract
    Nest_3_Abonus _abonus;                                          //  Bonus pool
    address _nTokeOfferMain;                                        //  NToken offering main contract
    address _destructionAddress;                                    //  Destruction contract address
    address _nTokenAuction;                                         //  NToken auction contract address
    struct PriceInfo {                                              //  Block price
        uint256 ethAmount;                                          //  ETH amount
        uint256 erc20Amount;                                        //  Erc20 amount
        uint256 frontBlock;                                         //  Last effective block
        address offerOwner;                                         //  Offering address
    }
    struct TokenInfo {                                              //  Token offer information
        mapping(uint256 => PriceInfo) priceInfoList;                //  Block price list, block number => block price
        uint256 latestOffer;                                        //  Latest effective block
    }
    uint256 destructionAmount = 0 ether;                            //  Amount of NEST to destroy to call prices
    uint256 effectTime = 0 days;                                    //  Waiting time to start calling prices
    mapping(address => TokenInfo) _tokenInfo;                       //  Token offer information
    mapping(address => bool) _blocklist;                            //  Block list
    mapping(address => uint256) _addressEffect;                     //  Effective time of address to call prices 
    mapping(address => bool) _offerMainMapping;                     //  Offering contract mapping
    uint256 _priceCost = 0.01 ether;                                //  Call price fee

    //  Real-time price  token, ETH amount, erc20 amount
    event NowTokenPrice(address a, uint256 b, uint256 c);
    
    /**
    * @dev Initialization method
    * @param voteFactory Voting contract address
    */
    constructor (address voteFactory) public {
        Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        _voteFactory = voteFactoryMap;
        _offerMain = Nest_3_OfferMain(address(voteFactoryMap.checkAddress("nest.v3.offerMain")));
        _nTokeOfferMain = address(voteFactoryMap.checkAddress("nest.nToken.offerMain"));
        _abonus = Nest_3_Abonus(address(voteFactoryMap.checkAddress("nest.v3.abonus")));
        _destructionAddress = address(voteFactoryMap.checkAddress("nest.v3.destruction"));
        _nestToken = ERC20(address(voteFactoryMap.checkAddress("nest")));
        _tokenMapping = Nest_NToken_TokenMapping(address(voteFactoryMap.checkAddress("nest.nToken.tokenMapping")));
        _nTokenAuction = address(voteFactoryMap.checkAddress("nest.nToken.tokenAuction"));
        _offerMainMapping[address(_offerMain)] = true;
        _offerMainMapping[address(_nTokeOfferMain)] = true;
    }
    
    /**
    * @dev Modify voting contract
    * @param voteFactory Voting contract address
    */
    function changeMapping(address voteFactory) public onlyOwner {
        Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        _voteFactory = voteFactoryMap;                                   
        _offerMain = Nest_3_OfferMain(address(voteFactoryMap.checkAddress("nest.v3.offerMain")));
        _nTokeOfferMain = address(voteFactoryMap.checkAddress("nest.nToken.offerMain"));
        _abonus = Nest_3_Abonus(address(voteFactoryMap.checkAddress("nest.v3.abonus")));
        _destructionAddress = address(voteFactoryMap.checkAddress("nest.v3.destruction"));
        _nestToken = ERC20(address(voteFactoryMap.checkAddress("nest")));
        _tokenMapping = Nest_NToken_TokenMapping(address(voteFactoryMap.checkAddress("nest.nToken.tokenMapping")));
        _nTokenAuction = address(voteFactoryMap.checkAddress("nest.nToken.tokenAuction"));
        _offerMainMapping[address(_offerMain)] = true;
        _offerMainMapping[address(_nTokeOfferMain)] = true;
    }
    
    /**
    * @dev Initialize token price charge parameters
    * @param tokenAddress Token address
    */
    function addPriceCost(address tokenAddress) public {
       
    }
    
    /**
    * @dev Add price
    * @param ethAmount ETH amount
    * @param tokenAmount Erc20 amount
    * @param endBlock Effective price block
    * @param tokenAddress Erc20 address
    * @param offerOwner Offering address
    */
    function addPrice(uint256 ethAmount, uint256 tokenAmount, uint256 endBlock, address tokenAddress, address offerOwner) public onlyOfferMain{
        // Add effective block price information
        TokenInfo storage tokenInfo = _tokenInfo[tokenAddress];
        PriceInfo storage priceInfo = tokenInfo.priceInfoList[endBlock];
        priceInfo.ethAmount = priceInfo.ethAmount.add(ethAmount);
        priceInfo.erc20Amount = priceInfo.erc20Amount.add(tokenAmount);
        if (endBlock != tokenInfo.latestOffer) {
            // If different block offer
            priceInfo.frontBlock = tokenInfo.latestOffer;
            tokenInfo.latestOffer = endBlock;
        }
    }
    
    /**
    * @dev Price modification in taker orders
    * @param ethAmount ETH amount
    * @param tokenAmount Erc20 amount
    * @param tokenAddress Token address 
    * @param endBlock Block of effective price
    */
    function changePrice(uint256 ethAmount, uint256 tokenAmount, address tokenAddress, uint256 endBlock) public onlyOfferMain {
        TokenInfo storage tokenInfo = _tokenInfo[tokenAddress];
        PriceInfo storage priceInfo = tokenInfo.priceInfoList[endBlock];
        priceInfo.ethAmount = priceInfo.ethAmount.sub(ethAmount);
        priceInfo.erc20Amount = priceInfo.erc20Amount.sub(tokenAmount);
    }
    
    /**
    * @dev Update and check the latest price
    * @param tokenAddress Token address
    * @return ethAmount ETH amount
    * @return erc20Amount Erc20 amount
    * @return blockNum Price block
    */
    function updateAndCheckPriceNow(address tokenAddress) public payable returns(uint256 ethAmount, uint256 erc20Amount, uint256 blockNum) {
        require(checkUseNestPrice(address(msg.sender)));
        mapping(uint256 => PriceInfo) storage priceInfoList = _tokenInfo[tokenAddress].priceInfoList;
        uint256 checkBlock = _tokenInfo[tokenAddress].latestOffer;
        while(checkBlock > 0 && (checkBlock >= block.number || priceInfoList[checkBlock].ethAmount == 0)) {
            checkBlock = priceInfoList[checkBlock].frontBlock;
        }
        require(checkBlock != 0);
        PriceInfo memory priceInfo = priceInfoList[checkBlock];
        address nToken = _tokenMapping.checkTokenMapping(tokenAddress);
        if (nToken == address(0x0)) {
            _abonus.switchToEth.value(_priceCost)(address(_nestToken));
        } else {
            _abonus.switchToEth.value(_priceCost)(address(nToken));
        }
        if (msg.value > _priceCost) {
            repayEth(address(msg.sender), msg.value.sub(_priceCost));
        }
        emit NowTokenPrice(tokenAddress,priceInfo.ethAmount, priceInfo.erc20Amount);
        return (priceInfo.ethAmount,priceInfo.erc20Amount, checkBlock);
    }
    
    /**
    * @dev Update and check the latest price-internal use
    * @param tokenAddress Token address
    * @return ethAmount ETH amount
    * @return erc20Amount Erc20 amount
    */
    function updateAndCheckPricePrivate(address tokenAddress) public view onlyOfferMain returns(uint256 ethAmount, uint256 erc20Amount) {
        mapping(uint256 => PriceInfo) storage priceInfoList = _tokenInfo[tokenAddress].priceInfoList;
        uint256 checkBlock = _tokenInfo[tokenAddress].latestOffer;
        while(checkBlock > 0 && (checkBlock >= block.number || priceInfoList[checkBlock].ethAmount == 0)) {
            checkBlock = priceInfoList[checkBlock].frontBlock;
        }
        if (checkBlock == 0) {
            return (0,0);
        }
        PriceInfo memory priceInfo = priceInfoList[checkBlock];
        return (priceInfo.ethAmount,priceInfo.erc20Amount);
    }
    
    /**
    * @dev Update and check the effective price list
    * @param tokenAddress Token address
    * @param num Number of prices to check
    * @return uint256[] price list
    */
    function updateAndCheckPriceList(address tokenAddress, uint256 num) public payable returns (uint256[] memory) {
        require(checkUseNestPrice(address(msg.sender)));
        mapping(uint256 => PriceInfo) storage priceInfoList = _tokenInfo[tokenAddress].priceInfoList;
        // Extract data
        uint256 length = num.mul(3);
        uint256 index = 0;
        uint256[] memory data = new uint256[](length);
        uint256 checkBlock = _tokenInfo[tokenAddress].latestOffer;
        while(index < length && checkBlock > 0){
            if (checkBlock < block.number && priceInfoList[checkBlock].ethAmount != 0) {
                // Add return data
                data[index++] = priceInfoList[checkBlock].ethAmount;
                data[index++] = priceInfoList[checkBlock].erc20Amount;
                data[index++] = checkBlock;
            }
            checkBlock = priceInfoList[checkBlock].frontBlock;
        }
        require(length == data.length);
        // Allocation
        address nToken = _tokenMapping.checkTokenMapping(tokenAddress);
        if (nToken == address(0x0)) {
            _abonus.switchToEth.value(_priceCost)(address(_nestToken));
        } else {
            _abonus.switchToEth.value(_priceCost)(address(nToken));
        }
        if (msg.value > _priceCost) {
            repayEth(address(msg.sender), msg.value.sub(_priceCost));
        }
        return data;
    }
    
    // Activate the price checking function
    function activation() public {
        _nestToken.safeTransferFrom(address(msg.sender), _destructionAddress, destructionAmount);
        _addressEffect[address(msg.sender)] = now.add(effectTime);
    }
    
    // Transfer ETH
    function repayEth(address accountAddress, uint256 asset) private {
        address payable addr = accountAddress.make_payable();
        addr.transfer(asset);
    }
    
    // Check block price - user account only
    function checkPriceForBlock(address tokenAddress, uint256 blockNum) public view returns (uint256 ethAmount, uint256 erc20Amount) {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        TokenInfo storage tokenInfo = _tokenInfo[tokenAddress];
        return (tokenInfo.priceInfoList[blockNum].ethAmount, tokenInfo.priceInfoList[blockNum].erc20Amount);
    }    
    
    // Check real-time price - user account only
    function checkPriceNow(address tokenAddress) public view returns (uint256 ethAmount, uint256 erc20Amount, uint256 blockNum) {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        mapping(uint256 => PriceInfo) storage priceInfoList = _tokenInfo[tokenAddress].priceInfoList;
        uint256 checkBlock = _tokenInfo[tokenAddress].latestOffer;
        while(checkBlock > 0 && (checkBlock >= block.number || priceInfoList[checkBlock].ethAmount == 0)) {
            checkBlock = priceInfoList[checkBlock].frontBlock;
        }
        if (checkBlock == 0) {
            return (0,0,0);
        }
        PriceInfo storage priceInfo = priceInfoList[checkBlock];
        return (priceInfo.ethAmount,priceInfo.erc20Amount, checkBlock);
    }
    
    // Check whether the price-checking functions can be called
    function checkUseNestPrice(address target) public view returns (bool) {
        if (!_blocklist[target] && _addressEffect[target] < now && _addressEffect[target] != 0) {
            return true;
        } else {
            return false;
        }
    }
    
    // Check whether the address is in the blocklist
    function checkBlocklist(address add) public view returns(bool) {
        return _blocklist[add];
    }
    
    // Check the amount of NEST to destroy to call prices
    function checkDestructionAmount() public view returns(uint256) {
        return destructionAmount;
    }
    
    // Check the waiting time to start calling prices
    function checkEffectTime() public view returns (uint256) {
        return effectTime;
    }
    
    // Check call price fee
    function checkPriceCost() public view returns (uint256) {
        return _priceCost;
    }
    
    // Modify the blocklist 
    function changeBlocklist(address add, bool isBlock) public onlyOwner {
        _blocklist[add] = isBlock;
    }
    
    // Amount of NEST to destroy to call price-checking functions
    function changeDestructionAmount(uint256 amount) public onlyOwner {
        destructionAmount = amount;
    }
    
    // Modify the waiting time to start calling prices
    function changeEffectTime(uint256 num) public onlyOwner {
        effectTime = num;
    }
    
    // Modify call price fee
    function changePriceCost(uint256 num) public onlyOwner {
        _priceCost = num;
    }

    // Offering contract only
    modifier onlyOfferMain(){
        require(_offerMainMapping[address(msg.sender)], "No authority");
        _;
    }
    
    // Vote administrators only
    modifier onlyOwner(){
        require(_voteFactory.checkOwners(msg.sender), "No authority");
        _;
    }
}

// Voting contract
interface Nest_3_VoteFactory {
    // Check address
	function checkAddress(string calldata name) external view returns (address contractAddress);
	// Check whether administrator
	function checkOwners(address man) external view returns (bool);
}

// NToken mapping contract
interface Nest_NToken_TokenMapping {
    function checkTokenMapping(address token) external view returns (address);
}

// NEST offer main contract
interface Nest_3_OfferMain {
    function checkTokenAllow(address token) external view returns(bool);
}

// Bonus pool contract
interface Nest_3_Abonus {
    function switchToEth(address token) external payable;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}