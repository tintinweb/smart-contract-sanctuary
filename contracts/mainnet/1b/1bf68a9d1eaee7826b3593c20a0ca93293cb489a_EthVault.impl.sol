pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./EthVault.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TIERC20 {
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;

    function balanceOf(address who) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint256);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EthVaultImpl is EthVault, SafeMath{
    event Deposit(string fromChain, string toChain, address fromAddr, bytes toAddr, address token, uint8 decimal, uint amount, uint depositId, uint block);
    event Withdraw(address hubContract, string fromChain, string toChain, bytes fromAddr, bytes toAddr, bytes token, bytes32[] bytes32s, uint[] uints);

    modifier onlyActivated {
        require(isActivated);
        _;
    }

    constructor(address[] memory _owner) public EthVault(_owner, _owner.length, address(0), address(0)) {
    }

    function getVersion() public pure returns(string memory){
        return "1028";
    }

    function changeActivate(bool activate) public onlyWallet {
        isActivated = activate;
    }

    function setTetherAddress(address tether) public onlyWallet {
        tetherAddress = tether;
    }

    function getChainId(string memory _chain) public view returns(bytes32){
        return sha256(abi.encodePacked(address(this), _chain));
    }

    function setValidChain(string memory _chain, bool valid) public onlyWallet {
        isValidChain[getChainId(_chain)] = valid;
    }

    function deposit(string memory toChain, bytes memory toAddr) payable public onlyActivated {
        require(isValidChain[getChainId(toChain)]);
        require(msg.value > 0);

        depositCount = depositCount + 1;
        emit Deposit(chain, toChain, msg.sender, toAddr, address(0), 18, msg.value, depositCount, block.number);
    }

    function depositToken(address token, string memory toChain, bytes memory toAddr, uint amount) public onlyActivated{
        require(isValidChain[getChainId(toChain)]);
        require(token != address(0));
        require(amount > 0);

        uint8 decimal = 0;
        if(token == tetherAddress){
            TIERC20(token).transferFrom(msg.sender, address(this), amount);
            decimal = TIERC20(token).decimals();
        }else{
            if(!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert();
            decimal = IERC20(token).decimals();
        }
        
        require(decimal > 0);

        depositCount = depositCount + 1;
        emit Deposit(chain, toChain, msg.sender, toAddr, token, decimal, amount, depositCount, block.number);
    }

    // Fix Data Info
    ///@param bytes32s [0]:govId, [1]:txHash
    ///@param uints [0]:amount, [1]:decimals
    function withdraw(
        address hubContract,
        string memory fromChain,
        bytes memory fromAddr,
        bytes memory toAddr,
        bytes memory token,
        bytes32[] memory bytes32s,
        uint[] memory uints,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyActivated {
        require(bytes32s.length >= 1);
        require(bytes32s[0] == sha256(abi.encodePacked(hubContract, chain, address(this))));
        require(uints.length >= 2);
        require(isValidChain[getChainId(fromChain)]);

        bytes32 whash = sha256(abi.encodePacked(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints));

        require(!isUsedWithdrawal[whash]);
        isUsedWithdrawal[whash] = true;

        uint validatorCount = _validate(whash, v, r, s);
        require(validatorCount >= required);

        address payable _toAddr = bytesToAddress(toAddr);
        address tokenAddress = bytesToAddress(token);
        if(tokenAddress == address(0)){
            if(!_toAddr.send(uints[0])) revert();
        }else{
            if(tokenAddress == tetherAddress){
                TIERC20(tokenAddress).transfer(_toAddr, uints[0]);
            }
            else{
                if(!IERC20(tokenAddress).transfer(_toAddr, uints[0])) revert();
            }
        }

        emit Withdraw(hubContract, fromChain, chain, fromAddr, toAddr, token, bytes32s, uints);
    }

    function _validate(bytes32 whash, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) private view returns(uint){
        uint validatorCount = 0;
        address[] memory vaList = new address[](owners.length);

        uint i=0;
        uint j=0;

        for(i; i<v.length; i++){
            address va = ecrecover(whash,v[i],r[i],s[i]);
            if(isOwner[va]){
                for(j=0; j<validatorCount; j++){
                    require(vaList[j] != va);
                }

                vaList[validatorCount] = va;
                validatorCount += 1;
            }
        }

        return validatorCount;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    function () payable external{
    }
}
