/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

/**

Deployed by Ren Project, https://renproject.io

Commit hash: 087fa49
Repository: https://github.com/renproject/gateway-sol
Issues: https://github.com/renproject/gateway-sol/issues

Licenses
@openzeppelin/contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/LICENSE
gateway-sol: https://github.com/renproject/gateway-sol/blob/master/LICENSE

*/

pragma solidity ^0.5.17;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Initializable {

  
  bool private initialized;

  
  bool private initializing;

  
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  
  function isConstructor() private view returns (bool) {
    
    
    
    
    
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  
  uint256[50] private ______gap;
}

contract Context is Initializable {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

contract IERC721Receiver {
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is Initializable, IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
    function balanceOf(address owner) public view returns (uint256 balance);

    
    function ownerOf(uint256 tokenId) public view returns (address owner);

    
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

interface IERC777Recipient {
    
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC777 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function granularity() external view returns (uint256);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address owner) external view returns (uint256);

    
    function send(address recipient, uint256 amount, bytes calldata data) external;

    
    function burn(uint256 amount, bytes calldata data) external;

    
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    
    function authorizeOperator(address operator) external;

    
    function revokeOperator(address operator) external;

    
    function defaultOperators() external view returns (address[] memory);

    
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

interface IMintGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);
}

interface IBurnGateway {
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}

interface IGateway {
    
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function mintFee() external view returns (uint256);

    
    function burn(bytes calldata _to, uint256 _amountScaled)
        external
        returns (uint256);

    function burnFee() external view returns (uint256);
}

interface IGatewayRegistry {
    
    
    event LogGatewayRegistered(
        string _symbol,
        string indexed _indexedSymbol,
        address indexed _tokenAddress,
        address indexed _gatewayAddress
    );
    event LogGatewayDeregistered(
        string _symbol,
        string indexed _indexedSymbol,
        address indexed _tokenAddress,
        address indexed _gatewayAddress
    );
    event LogGatewayUpdated(
        address indexed _tokenAddress,
        address indexed _currentGatewayAddress,
        address indexed _newGatewayAddress
    );

    
    function getGateways(address _start, uint256 _count)
        external
        view
        returns (address[] memory);

    
    function getRenTokens(address _start, uint256 _count)
        external
        view
        returns (address[] memory);

    
    
    
    
    function getGatewayByToken(address _tokenAddress)
        external
        view
        returns (IGateway);

    
    
    
    
    function getGatewayBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IGateway);

    
    
    
    
    function getTokenBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IERC20);
}

interface IERC1155 {
    
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    
    event URI(string value, uint256 indexed id);

    
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    
    function setApprovalForAll(address operator, bool approved) external;

    
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IERC1155Receiver {
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

contract GenericAdapter is
    Ownable,
    IERC721Receiver,
    IERC777Recipient,
    IERC1155Receiver
{
    using SafeMath for uint256;

    IGatewayRegistry registry;

    constructor(IGatewayRegistry _registry) public {
        Ownable.initialize(msg.sender);
        registry = _registry;
    }

    function directMint(
        
        string calldata _symbol,
        address _account,
        uint256 _submitterFee,
        
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        
        if (_account == msg.sender) {
            _submitterFee = 0;
        }

        
        bytes32 payloadHash =
            keccak256(abi.encode(_symbol, _account, _submitterFee));

        
        uint256 amount =
            registry.getGatewayBySymbol(_symbol).mint(
                payloadHash,
                _amount,
                _nHash,
                _sig
            );

        IERC20 token = registry.getTokenBySymbol(_symbol);
        token.transfer(_account, amount.sub(_submitterFee));

        
        if (_submitterFee > 0) {
            token.transfer(msg.sender, _submitterFee);
        }
    }

    
    address currentAccount;

    function genericCall(
        
        string calldata _symbol,
        address _account,
        address _contract,
        bytes calldata _contractParams,
        IERC20[] calldata _refundTokens,
        uint256 _submitterFee,
        
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external {
        address previousAccount = currentAccount;
        currentAccount = _account;

        
        
        
        
        
        _genericCallInner(
            _symbol,
            _account,
            _contract,
            _contractParams,
            _refundTokens,
            _submitterFee,
            _amount,
            _nHash,
            _sig
        );

        
        currentAccount = previousAccount;
    }

    function _genericCallInner(
        
        string memory _symbol,
        address _account,
        address _contract,
        bytes memory _contractParams,
        IERC20[] memory _refundTokens,
        uint256 _submitterFee,
        
        uint256 _amount,
        bytes32 _nHash,
        bytes memory _sig
    ) internal {
        
        if (_account == msg.sender) {
            _submitterFee = 0;
        }

        
        bytes32 payloadHash =
            keccak256(
                abi.encode(
                    _symbol,
                    _account,
                    _contract,
                    _contractParams,
                    _refundTokens,
                    _submitterFee
                )
            );

        _mintAndCall(
            payloadHash,
            _symbol,
            _contract,
            _contractParams,
            _submitterFee,
            _amount,
            _nHash,
            _sig
        );

        _returnReceivedTokens(_symbol, _refundTokens, _submitterFee);
    }

    function _returnReceivedTokens(
        string memory _symbol,
        IERC20[] memory _refundTokens,
        uint256 _submitterFee
    ) internal {
        IERC20 token = registry.getTokenBySymbol(_symbol);

        
        
        
        
        for (uint256 i = 0; i < _refundTokens.length; i++) {
            IERC20 refundToken = IERC20(_refundTokens[i]);
            uint256 refundBalance = refundToken.balanceOf(address(this));
            if (refundBalance > 0) {
                refundToken.transfer(currentAccount, refundBalance);
            }
        }

        
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance > _submitterFee) {
            token.transfer(currentAccount, tokenBalance.sub(_submitterFee));
        }

        
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool success, ) = currentAccount.call.value(ethBalance)("");
            require(success);
        }

        
        if (_submitterFee > 0) {
            token.transfer(msg.sender, _submitterFee);
        }
    }

    function _mintAndCall(
        bytes32 payloadHash,
        string memory _symbol,
        address _contract,
        bytes memory _contractParams,
        uint256 _submitterFee,
        uint256 _amount,
        bytes32 _nHash,
        bytes memory _sig
    ) internal {
        
        uint256 amount =
            registry.getGatewayBySymbol(_symbol).mint(
                payloadHash,
                _amount,
                _nHash,
                _sig
            );

        IERC20 token = registry.getTokenBySymbol(_symbol);

        
        uint256 oldApproval = token.allowance(address(this), _contract);
        token.approve(_contract, oldApproval.add(amount.sub(_submitterFee)));

        
        arbitraryCall(_contract, _contractParams);

        
        token.approve(_contract, oldApproval);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        
        IERC721(msg.sender).safeTransferFrom(
            address(this),
            currentAccount,
            tokenId,
            data
        );
        return this.onERC721Received.selector;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256 amount,
        bytes memory userData,
        bytes memory
    ) public {
        IERC777(msg.sender).send(currentAccount, amount, userData);
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        IERC1155(msg.sender).safeTransferFrom(
            address(this),
            currentAccount,
            id,
            value,
            data
        );
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        IERC1155(msg.sender).safeBatchTransferFrom(
            address(this),
            currentAccount,
            ids,
            values,
            data
        );
        return this.onERC1155BatchReceived.selector;
    }

    
    
    function _recover(address _contract, bytes calldata _contractParams)
        external
        onlyOwner
    {
        arbitraryCall(_contract, _contractParams);
    }

    function arbitraryCall(address _contract, bytes memory _contractParams)
        internal
    {
        (bool success, bytes memory result) = _contract.call(_contractParams);
        if (!success) {
            
            if (result.length < 68) {
                revert(
                    "GenericAdapter: contract call failed without revert reason"
                );
            }
            
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
    }
}