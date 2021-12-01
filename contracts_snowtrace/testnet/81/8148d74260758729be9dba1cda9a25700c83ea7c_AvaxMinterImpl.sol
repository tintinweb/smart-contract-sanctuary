// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract AvaxMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "AvaxMinter20211108";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract MinterStorage {
    string public chain;
    bool public isActivated = true;

    uint public depositCount = 0;

    mapping(bytes32 => bool) public isConfirmed;
    mapping(bytes32 => bool) public isValidChain;

    mapping(bytes32 => bytes) public tokens;
    mapping(bytes32 => address) public tokenAddr;
    mapping(address => bytes32) public tokenSummaries;

    bytes32 public govId;

    uint public bridgingFee;
    uint public bridgingFeeWithData;
    uint public gasLimitForBridgeReceiver;
    address payable public feeGovernance;

    uint public taxRate = 10; // 0.01% interval
    address public taxReceiver = 0xE9f3604B85c9672728eEecf689cf1F0cF7Dd03F2;

    address public tokenDeployer;

    mapping (address => uint) public minRequestAmount;

    address public policyAdmin;
    mapping(bytes32 => uint256) public chainFee;
    mapping(bytes32 => uint256) public chainFeeWithData;

    mapping(bytes32 => uint256) public chainUintsLength;
    mapping(bytes32 => uint256) public chainAddressLength;
    uint256 public chainTokenLength;

    mapping(address => bool) public silentTokenList;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract XdaiMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "XdaiMinter20211108";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract OecMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "OecMinter20211108";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract MoonRiverMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "MoonRiverMinter20211108";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
                "SafeERC20: approve from non-zero to non-zero allowance"
               );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
    function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract MaticMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "MaticMinter20210817A";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract HecoMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "HecoMinter20210817A";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract HarmonyMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "HarmonyMinter20211108";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract FantomMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "FantomMinter20211108";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract EthMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "EthMinter20210929";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract CeloMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "CeloMinter20210929";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Minter.storage.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeMint(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.mint.selector, account, amount));
    }

    function safeBurn(IERC20 token, address account, uint256 amount) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.burn.selector, account, amount));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IGovernance {
    function required() external view returns(uint);
    function getOwners() external view returns(address[] memory);
    function isOwner(address owner) external view returns(bool);
}

interface IFarm {
    function deposit(uint amount) external;
    function withdrawAll() external;
    function withdraw(address toAddr, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address, uint256) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external returns (bool);
    function burn(address owner, uint256 tokenId) external returns (bool);
}

interface IProxy {
    function owner() external view returns (address);
    function getChain() external view returns (string memory);
    function getAdmin() external view returns (address);
    function getImplementation() external view returns (address);
}

interface Deployer {
    function deployToken(uint8 decimals) external returns (address);
    function deployNFT() external returns (address);
    function deployTokenWithInit(string memory name, string memory symbol, uint8 decimals) external returns (address);
    function deployNFTWithInit(string memory name, string memory symbol) external returns (address);
}

interface OrbitBridgeReceiver {
    function onTokenBridgeReceived(address _token, uint256 _value, bytes calldata _data) external returns(uint);
	function onNFTBridgeReceived(address _token, uint256 _tokenId, bytes calldata _data) external returns(uint);
}

contract BscMinterImpl is MinterStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event Swap(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);
    event SwapNFT(string fromChain, bytes fromAddr, bytes toAddr, address tokenAddress, bytes32[] bytes32s, uint[] uints, bytes data);

    event SwapRequest(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint8 decimal, uint amount, uint depositId, bytes data);
    event SwapRequestNFT(string toChain, address fromAddr, bytes toAddr, bytes token, address tokenAddress, uint tokenId, uint amount, uint depositId, bytes data);
    event BridgeReceiverResult(bool success, bytes fromAddr, address tokenAddress, bytes data);

    constructor() public payable { }

    modifier onlyGovernance {
        require(msg.sender == governance_());
        _;
    }

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    modifier onlyPolicyAdmin {
        require(msg.sender == policyAdmin);
        _;
    }

    function admin_() internal view returns (address) {
        return IProxy(address(this)).getAdmin();
    }

    function governance_() internal view returns (address) {
        return IProxy(admin_()).owner();
    }

    function getVersion() public pure returns(string memory){
        return "BscMinter20211019";
    }

    function getTokenAddress(bytes memory token) public view returns(address){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        return tokenAddr[tokenSummary];
    }

    function getChainId(string memory chainSymbol) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), chainSymbol));
    }

    function setChainSymbol(string memory _chain) public onlyGovernance {
        chain = _chain;
    }

    function setValidChain(string memory _chain, bool valid, uint fromAddrLen, uint uintsLen) public onlyGovernance {
        bytes32 chainId = getChainId(_chain);
        require(chainId != getChainId(chain));
        isValidChain[chainId] = valid;
        if(valid){
            chainAddressLength[chainId] = fromAddrLen;
            chainUintsLength[chainId] = uintsLen;
        }
        else{
            chainAddressLength[chainId] = 0;
            chainUintsLength[chainId] = 0;
        }
    }

    function setGovId(bytes32 _govId) public onlyGovernance {
        govId = _govId;
    }

    function setTaxRate(uint _taxRate) public onlyGovernance {
        require(_taxRate < 10000);
        taxRate = _taxRate;
    }

    function setTaxReceiver(address _taxReceiver) public onlyGovernance {
        require(_taxReceiver != address(0));
        taxReceiver = _taxReceiver;
    }

    function setTokenDeployer(address _deployer) public onlyGovernance {
        require(_deployer != address(0));
        tokenDeployer = _deployer;
    }

    function setPolicyAdmin(address _policyAdmin) public onlyGovernance {
        require(_policyAdmin != address(0));
        policyAdmin = _policyAdmin;
    }

    function changeActivate(bool activate) public onlyPolicyAdmin {
        isActivated = activate;
    }

    function setMinRequestSwapAmount(address _token, uint amount) public onlyPolicyAdmin {
        require(_token != address(0));
        require(tokenSummaries[_token] != 0);
        minRequestAmount[_token] = amount;
    }

    function setChainFee(string memory chainSymbol, uint256 _fee, uint256 _feeWithData) public onlyPolicyAdmin {
        bytes32 chainId = getChainId(chainSymbol);
        require(isValidChain[chainId]);

        chainFee[chainId] = _fee;
        chainFeeWithData[chainId] = _feeWithData;
    }

    function setFeeGovernance(address payable _feeGovernance) public onlyGovernance {
        require(_feeGovernance != address(0));
        feeGovernance = _feeGovernance;
    }

    function setGasLimitForBridgeReceiver(uint256 _gasLimitForBridgeReceiver) public onlyPolicyAdmin {
        gasLimitForBridgeReceiver = _gasLimitForBridgeReceiver;
    }

    function setSilentToken(address token, bool v) public onlyPolicyAdmin {
        require(token != address(0));

        silentTokenList[token] = v;
    }

    function setTokenLength(uint256 tokenLen) public onlyGovernance {
        require(tokenLen != 0);
        chainTokenLength = tokenLen;
    }

    function addToken(bytes memory token, address tokenAddress) public onlyGovernance {
        require(tokenSummaries[tokenAddress] == 0);

        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    function addTokenWithDeploy(bool isFungible, bytes memory token, string memory name, string memory symbol, uint8 decimals) public onlyPolicyAdmin {
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));
        require(tokenAddr[tokenSummary] == address(0));

        address tokenAddress;
        if(isFungible)
            tokenAddress = Deployer(tokenDeployer).deployTokenWithInit(name, symbol, decimals);
        else
            tokenAddress = Deployer(tokenDeployer).deployNFTWithInit(name, symbol);
        require(tokenAddress != address(0));

        tokens[tokenSummary] = token;
        tokenAddr[tokenSummary] = tokenAddress;
        tokenSummaries[tokenAddress] = tokenSummary;
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function swap(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(uints[1] <= 100);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address tokenAddress = getTokenAddress(token, uints[1]);
        if(tokenAddress == address(0)){
            revert();
        }else{
            IERC20(tokenAddress).safeMint(toAddr, uints[0]);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onTokenBridgeReceived(address,uint256,bytes)", tokenAddress, uints[0], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, tokenAddress, data);
        }

        emit Swap(fromChain, fromAddr, abi.encodePacked(toAddr), tokenAddress, bytes32s, uints, data);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:tokenId
    function swapNFT(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        address toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        bytes memory data,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length == 2);
        require(bytes32s[0] == govId);
        require(uints.length == chainUintsLength[getChainId(fromChain)]);
        require(fromAddr.length == chainAddressLength[getChainId(fromChain)]);
        require(token.length == chainTokenLength);

        bytes32 hash = sha256(abi.encodePacked("NFT", hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints, data));

        require(!isConfirmed[hash]);
        isConfirmed[hash] = true;

        uint validatorCount = _validate(hash, v, r, s);
        require(validatorCount >= IGovernance(governance_()).required());

        address nftAddress = getNFTAddress(token);
        if(nftAddress == address(0)){
            revert();
        }else{
            require(IERC721(nftAddress).mint(toAddr, uints[1]));
            require(IERC721(nftAddress).ownerOf(uints[1]) == toAddr);
        }

        if(isContract(toAddr) && data.length != 0){
            bool result;
            bytes memory callbytes = abi.encodeWithSignature("onNFTBridgeReceived(address,uint256,bytes)", nftAddress, uints[1], data);
            if (gasLimitForBridgeReceiver > 0) {
                (result, ) = toAddr.call{gas : gasLimitForBridgeReceiver}(callbytes);
            } else {
                (result, ) = toAddr.call(callbytes);
            }
            emit BridgeReceiverResult(result, fromAddr, nftAddress, data);
        }

        emit SwapNFT(fromChain, fromAddr, abi.encodePacked(toAddr), nftAddress, bytes32s, uints, data);
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwap(tokenAddress, toChain, toAddr, amount, "");
    }

    function requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwap(tokenAddress, toChain, toAddr, amount, data);
    }

    function _requestSwap(address tokenAddress, string memory toChain, bytes memory toAddr, uint amount, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(tokenAddress != address(0));
        require(amount > 0);
        require(!silentTokenList[tokenAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[tokenAddress];
        require(tokenSummaries[tokenAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        IERC20(tokenAddress).safeBurn(msg.sender, amount);

        uint8 decimal = IERC20(tokenAddress).decimals();
        require(decimal > 0);

        if(taxRate > 0 && taxReceiver != address(0)){
            uint tax = _payTax(token, tokenAddress, amount, decimal);
            amount = amount.sub(tax);
        }
        require(minRequestAmount[tokenAddress] <= amount);

        depositCount = depositCount + 1;
        emit SwapRequest(toChain, msg.sender, toAddr, token, tokenAddress, decimal, amount, depositCount, data);
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr) public payable onlyActivated {
        require(msg.value >= chainFee[getChainId(toChain)]);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, "");
    }

    function requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) public payable onlyActivated {
        require(msg.value >= chainFeeWithData[getChainId(toChain)]);
        require(data.length != 0);
        _requestSwapNFT(nftAddress, tokenId, toChain, toAddr, data);
    }

    function _requestSwapNFT(address nftAddress, uint tokenId, string memory toChain, bytes memory toAddr, bytes memory data) private {
        require(isValidChain[getChainId(toChain)]);
        require(nftAddress != address(0));
        require(!silentTokenList[nftAddress]);

        _transferBridgingFee(msg.value);

        bytes32 tokenSummary = tokenSummaries[nftAddress];
        require(tokenSummaries[nftAddress] != 0);

        bytes memory token = tokens[tokenSummary];
        require(token.length != 0);

        require(IERC721(nftAddress).ownerOf(tokenId) == msg.sender);
        require(IERC721(nftAddress).burn(msg.sender, tokenId));

        depositCount = depositCount + 1;
        emit SwapRequestNFT(toChain, msg.sender, toAddr, token, nftAddress, tokenId, 1, depositCount, data);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](IGovernance(governance_()).getOwners().length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(IGovernance(governance_()).isOwner(va)){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function getTokenAddress(bytes memory token, uint decimals) private returns(address tokenAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        tokenAddress = tokenAddr[tokenSummary];
        if(tokenAddress == address(0)){
            require(tokenDeployer != address(0));
            tokenAddress = Deployer(tokenDeployer).deployToken(uint8(decimals));
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = tokenAddress;
            tokenSummaries[tokenAddress] = tokenSummary;
        }
    }

    function getNFTAddress(bytes memory token) private returns(address nftAddress){
        bytes32 tokenSummary = sha256(abi.encodePacked(chain, token));

        nftAddress = tokenAddr[tokenSummary];
        if(nftAddress == address(0)){
            require(tokenDeployer != address(0));
            nftAddress = Deployer(tokenDeployer).deployNFT();
            tokens[tokenSummary] = token;
            tokenAddr[tokenSummary] = nftAddress;
            tokenSummaries[nftAddress] = tokenSummary;
        }
    }

    function _transferBridgingFee(uint amount) private {
        require(feeGovernance != address(0));

        (bool result,) = feeGovernance.call{value: amount}("");
        if(!result){
            revert();
        }
    }

    function _payTax(bytes memory token, address tokenAddress, uint amount, uint8 decimal) private returns (uint tax) {
        tax = amount.mul(taxRate).div(10000);
        if(tax > 0){
            depositCount = depositCount + 1;
            emit SwapRequest("ORBIT", msg.sender, abi.encodePacked(taxReceiver), token, tokenAddress, decimal, tax, depositCount, "");
        }
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    receive () external payable { revert(); }
    fallback () external payable { revert(); }
}