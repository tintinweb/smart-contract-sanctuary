//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/ERC20/ERC20.sol";
import "../token/ERC721/ERC721.sol";
import "../token/ERC2917/ERC2917.sol";
import "../libraries/ConfigFeesERC2917.sol";

contract FactoryMaster {
    ERC20[] public childrenErc20;
    ERC721[] public childrenErc721;
    ERC2917[] public childrenErc2917;

    uint constant fee_erc20 = 0.3 ether;
    uint constant fee_erc721 = 0.4 ether;
    uint constant fee_erc2917 = 0.5 ether;
   
    event ChildCreatedERC20(address childAddress, string name, string symbol);
    event ChildCreatedERC721(address childAddress, string name, string symbol);
    event ChildCreated2917(
        address childAddress,
        string name,
        string symbol,
        uint256 _interestsRate
    );

    enum Types {
        none,
        erc20,
        erc721,
        erc2917
    }

    function createChild(Types types,string memory name,string memory symbol,uint256 _interestsRate) external payable {

        require(types != Types.none, "you must enter the word 1");
        require(keccak256(abi.encodePacked((name))) !=keccak256(abi.encodePacked((""))),"requireed value");
        require(keccak256(abi.encodePacked((symbol))) !=keccak256(abi.encodePacked((""))),"requireed value");

        if (types == Types.erc20) {

            require(msg.value>=fee_erc20,"ERC20:value must be greater than 0.2");

            ERC20 child = new ERC20(name, symbol);
            childrenErc20.push(child);
            emit ChildCreatedERC20(address(child), name, symbol);
            
        }
        if (types == Types.erc721) {
            
            require(msg.value>=fee_erc721,"ERC721:value must be greater than 0.3");

            ERC721 child = new ERC721(name, symbol);
            childrenErc721.push(child);
            emit ChildCreatedERC721(address(child), name, symbol);
        }
        if (types == Types.erc2917) {

            require(_interestsRate >= 0, "value must be greater than 0");
            require(msg.value>=ConfigFeeERC2917.FEE_CREATE_ERC2917_TOKEN,"NOT ENOUGH FEES");

            ERC2917 child = new ERC2917(name, symbol, _interestsRate);
            childrenErc2917.push(child);
            emit ChildCreated2917(address(child), name, symbol, _interestsRate);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "../../libraries/Context.sol";
import "../../libraries/SafeMath.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {

     using SafeMath for uint256;

    mapping(address => uint256)  _balances;
    mapping(address => mapping(address => uint256))   _allowances;

    uint256  _totalSupply=10000;

    string private _name;
    string private _symbol;
    uint8  private _decimals = 18;
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}





      function deposit(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: mint to the zero address");

        _balances[account] += amount;
        _totalSupply = _totalSupply.add(amount);

        emit Transfer(address(0), account, amount);
        return true;
    }

    function withdrawal(address account, uint256 amount) external override returns (bool) {
        require(account != address(0), "ERC20: burn from the zero address");
        
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[account] = accountBalance - amount;
        
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
        return true;
    }
    
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "../../libraries/Address.sol";
import "../../libraries/Context.sol";
import "../../libraries/Strings.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Receiver.sol";
import "../../libraries/introspection/ERC165.sol";

contract ERC721 is Context, ERC165,IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : " ";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC20/ERC20.sol";
import "./interfaces/IERC2917.sol";
import "../../libraries/Upgradable.sol";
import "../../libraries/SafeMath.sol";
import "../../libraries/ReentrancyGuard.sol";

contract ERC2917 is IERC2917,ERC20,UpgradableProduct,UpgradableGovernance,ReentrancyGuard
{
    using SafeMath for uint256;

    uint256 public mintCumulation;
    uint256 public usdPerBlock;
    uint256 public lastRewardBlock;
    uint256 public totalProductivity;
    uint256 public accAmountPerShare;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt; 
    }

    mapping(address => UserInfo) public users;

    // creation of the interests token.
    constructor(string memory name,string memory symbol,uint256 _interestsRate)
        ERC20(name,symbol)
        UpgradableProduct()
        UpgradableGovernance()
    {
        usdPerBlock = _interestsRate;
    }

    // function initialize(
    //     uint256 _interestsRate,
    //     string memory _name,
    //     string memory _symbol,
    //     uint8 _decimals,
    //     address _impl,
    //     address _governor
    // ) external {
    //     impl = _impl;
    //     governor = _governor;
    //     name = _name;
    //     symbol = _symbol;
    //     decimals = _decimals;
    //     usdPerBlock = _interestsRate;
    // }

    function increment() public {
        usdPerBlock++;
    }

    function changeInterestRatePerBlock(uint256 value)
        external
        override
        requireGovernor
        returns (bool)
    {
        uint256 old = usdPerBlock;
        require(value != old, "AMOUNT_PER_BLOCK_NO_CHANGE");

        usdPerBlock = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }

    function enter(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(this.deposit(account, amount), "INVALID DEPOSIT");
        return increaseProductivity(account, amount);
    }

    function exit(address account, uint256 amount)
        external
        override
        returns (bool)
    {
        require(this.withdrawal(account, amount), "INVALID WITHDRAWAL");
        return decreaseProductivity(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(decreaseProductivity(from, amount), "INVALID DEC PROD");
        require(increaseProductivity(to, amount), "INVALID INC PROD");
    }

       function update() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number.sub(lastRewardBlock);

        uint256 reward = multiplier.mul(usdPerBlock);

        _balances[address(this)] = _balances[address(this)].add(reward);

        _totalSupply = _totalSupply.add(reward);

        accAmountPerShare = accAmountPerShare.add(
            reward.mul(1e12).div(totalProductivity)
        );
        lastRewardBlock = block.number;
    }

    function increaseProductivity(address user, uint256 value)
        internal
        returns (bool)
    {
        require(value > 0, "PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO");

        UserInfo storage userInfo = users[user];
        update();
        if (userInfo.amount > 0) {
            uint256 pending = userInfo
            .amount
            .mul(accAmountPerShare)
            .div(1e12)
            .sub(userInfo.rewardDebt);
            _transfer(address(this), user, pending);
            mintCumulation = mintCumulation.add(pending);
        }

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        emit ProductivityIncreased(user, value);
        return true;
    }

    function decreaseProductivity(address user, uint256 value)
        internal
        returns (bool)
    {
        require(value > 0, "INSUFFICIENT_PRODUCTIVITY");

        UserInfo storage userInfo = users[user];
        require(userInfo.amount >= value, "Decrease : FORBIDDEN");
        update();
        uint256 pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(
            userInfo.rewardDebt
        );
        _transfer(address(this), user, pending);
        mintCumulation = mintCumulation.add(pending);
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);

        emit ProductivityDecreased(user, value);
        return true;
    }

    function take() external view override returns (uint256) {
        UserInfo storage userInfo = users[msg.sender];
        uint256 _accAmountPerShare = accAmountPerShare;

        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            );
    }

    function takeWithAddress(address user) external view returns (uint256) {
        UserInfo storage userInfo = users[user];
        uint256 _accAmountPerShare = accAmountPerShare;
       
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            );
    }

    function takeWithBlock() external view override returns (uint256, uint256) {
        UserInfo storage userInfo = users[msg.sender];
        uint256 _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (block.number > lastRewardBlock && totalProductivity != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(usdPerBlock);
            _accAmountPerShare = _accAmountPerShare.add(
                reward.mul(1e12).div(totalProductivity)
            );
        }
        return (
            userInfo.amount.mul(_accAmountPerShare).div(1e12).sub(
                userInfo.rewardDebt
            ),
            block.number
        );
    }

    function mint() external override nonReentrant returns (uint256) {
        return 0;
    }

    function getProductivity(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (users[user].amount, totalProductivity);
    }

    function interestsPerBlock() external view override returns (uint256) {
        return accAmountPerShare;
    }

    function getStatus()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            lastRewardBlock,
            totalProductivity,
            accAmountPerShare,
            mintCumulation
        );
    }
}

pragma solidity >=0.5.16;

library ConfigFeeERC2917 {
    uint256 public constant FEE_CREATE_ERC2917_TOKEN = 10000*10**18;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    //erc2917 and erc20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function deposit(address account, uint256 amount) external returns (bool);
    function withdrawal(address account, uint256 amount) external returns (bool);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library SafeMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../../libraries/introspection/IERC165.sol";
interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
 
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
  
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../ERC20/interfaces/IERC20.sol';

interface IERC2917 is IERC20{

    event InterestRatePerBlockChanged (uint oldValue, uint newValue);
    event ProductivityIncreased (address indexed user, uint value);
    event ProductivityDecreased (address indexed user, uint value);

    function interestsPerBlock() external view returns (uint);
    function changeInterestRatePerBlock(uint value) external returns (bool);
    function getProductivity(address user) external view returns (uint, uint);
    function take() external view returns (uint);
    function takeWithBlock() external view returns (uint, uint);
    function mint() external returns (uint);
    function enter(address account, uint256 amount) external returns (bool);
    function exit(address account, uint256 amount) external returns (bool);
    function getStatus() external view returns (uint lastRewardBlock, uint totalProductivity, uint accAmountPerShare, uint mintCumulation);

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract UpgradableProduct {
    address public impl;

    event ImplChanged(address indexed _oldImpl, address indexed _newImpl);

    constructor() {
        impl = msg.sender;
    }

    function initializeUpgradableProduct() public {
        impl = msg.sender;
    }

    modifier requireImpl() {
        require(msg.sender == impl, "FORBIDDEN");
        _;
    }

    function upgradeImpl(address _newImpl) public requireImpl {
        require(_newImpl != address(0), "INVALID_ADDRESS");
        require(_newImpl != impl, "NO_CHANGE");
        address lastImpl = impl;
        impl = _newImpl;
        emit ImplChanged(lastImpl, _newImpl);
    }
}

contract UpgradableGovernance {
    address public governor;

    event GovernorChanged(
        address indexed _oldGovernor,
        address indexed _newGovernor
    );

    constructor() {
        governor = msg.sender;
    }

    function initializeUpgradableGovernance() public {
        governor = msg.sender;
    }

    modifier requireGovernor() {
        require(msg.sender == governor, "FORBIDDEN");
        _;
    }

    function upgradeGovernance(address _newGovernor) public requireGovernor {
        require(_newGovernor != address(0), "INVALID_ADDRESS");
        require(_newGovernor != governor, "NO_CHANGE");
        address lastGovernor = governor;
        governor = _newGovernor;
        emit GovernorChanged(lastGovernor, _newGovernor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
       
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

