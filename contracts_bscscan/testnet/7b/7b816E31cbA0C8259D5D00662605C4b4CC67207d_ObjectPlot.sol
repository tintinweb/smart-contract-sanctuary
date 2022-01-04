pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}



pragma solidity ^0.8.0;


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;

    // ################################################################################ 用户建筑

    //token的详情
    struct UserNftPlot {
        //nft id
        uint256 token_id;
        //建筑介绍
        string name;
        //持有用户
        address user_address;
        //获得时间
        uint256 create_time;
        //建筑照片
        string image_suffix;
        //建筑类型
        uint256 plot_type;
        //建筑坐标
        uint256 current_x;
        //建筑坐标
        uint256 current_y;
        //建筑宽
        uint256 block_width;
        //建筑高
        uint256 block_height;
        uint256 _param1;
        uint256 _param2;
    }

    //NFT建筑列表。ID对建筑
    mapping(uint256 => UserNftPlot) public nftList;
    //用户持有建筑列表。用户对建筑
    mapping(address => UserNftPlot[]) public userHoldList;
    mapping(uint256 => uint256) public privateGlobalUint;
    //基础uri
    string baseURI;

    //获取用户已持有nft数量
    function getUserTokenLen(address user) public view returns (uint256) {return userHoldList[user].length;}
    //获取用户获得的所有nft地块
    function getUserPlotList(address user) public view returns (UserNftPlot[] memory) {return userHoldList[user];}
    // ################################################################################ 用户建筑

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // 从令牌 ID 到所有者地址的映射
    mapping(uint256 => address) private _owners;

    // 将所有者地址映射到令牌计数
    mapping(address => uint256) private _balances;

    // 从令牌 ID 映射到批准的地址
    mapping(uint256 => address) private _tokenApprovals;

    // 从所有者到运营商批准的映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI, tokenId)) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
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

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // ################ 转账改变用户所属
        if (privateGlobalUint[5] == 1) {
            __transfer(from, to, tokenId);
        }
        emit Transfer(from, to, tokenId);
    }

    // 交易Token
    function __transfer(address _from, address _to, uint256 _tokenId) private {
        // 发送方的tokenId数组;
        UserNftPlot[] storage u_ = userHoldList[_from];
        for (uint256 i = 0; i < u_.length; i++) {
            if (u_[i].token_id == _tokenId) {
                if (u_.length == i + 1) {
                    // 如果用户只有一个的话, 或者减少的是最后一个的话; 直接弹出最后一个;
                    u_.pop();
                } else {
                    // 如果不是第一个, 就删除那个, 然后把最后一个填补那个删除的位置, 再弹出最后一个;
                    delete u_[i];
                    u_[i] = u_[u_.length - 1];
                    u_.pop();
                }
                break;
            }
        }
        // 接收方获得
        nftList[_tokenId].user_address = _to;
        userHoldList[_to].push(nftList[_tokenId]);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

pragma solidity ^0.8.0;

abstract contract ERC721URIStorage is ERC721 {

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

library SafeMath {function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;}

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;}

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;}
}

import "./CoinFactoryAdminRole.sol";
pragma solidity ^0.8.0;

contract ObjectPlot is ERC721URIStorage, CoinFactoryAdminRole {

    using SafeMath for uint256;
    mapping(string => uint256) public plot_name_type;

    mapping(uint256 => address) public privateGlobalAdd;
    mapping(uint256 => string) public methodFacadeConfig;
    uint256[][] public xySize;
    mapping(uint256 => mapping(uint256 => uint256)) public xySizeUse;

    event NewEpicNFTMinted(address sender, uint256 tokenId, string image_suffix);

    constructor() ERC721 ("PLOTNFT", "plot") {
        _owner = msg.sender;
        addCoinFactoryAdmin(msg.sender);
        privateGlobalUint[1] = privateGlobalUint[1].add(1);
        privateGlobalUint[2] = privateGlobalUint[2].add(1);

        privateGlobalUint[3] = 0;
        privateGlobalUint[4] = 10;
        privateGlobalUint[5] = 1;
    }

    function makePlotNFT(address sender, string memory name, string memory image_suffix, uint256 c_x, uint256 c_y, uint256 block_width, uint256 block_height) public onlyCoinFactoryAdmin {
        uint256 newItemId = privateGlobalUint[2];

        string memory finalTokenUri = string(abi.encodePacked('?tokenId=', newItemId));
        _safeMint(sender, newItemId);
        _setTokenURI(newItemId, finalTokenUri);

        // ################ 记载所属列表
        if (privateGlobalUint[5] == 1) {
            require(xySizeUse[c_x][c_y] == 0, "dev : xy used");
            xySizeUse[c_x][c_y] = 1;
            xySize.push([c_x, c_y, block_width, block_height]);

            uint256 type_ = getNextType(name);
            UserNftPlot memory userNftPlot = UserNftPlot(newItemId, name, sender, block.timestamp, image_suffix, type_, c_x, c_y, block_width, block_height, 0, 0);
            //储存盲盒对象
            nftList[newItemId] = userNftPlot;
            //用户持有地块列表
            userHoldList[sender].push(userNftPlot);
        }

        privateGlobalUint[2] = privateGlobalUint[2].add(1);
        emit NewEpicNFTMinted(sender, newItemId, image_suffix);
    }

    //得到坐标参数
    function getLastXYParam(uint256 param_) public view returns (uint256[] memory, uint256, uint256, uint256){
        return (xySize[xySize.length.sub(1)], xySize.length, privateGlobalUint[3], privateGlobalUint[4]);
    }

    //得到新type
    function getNextType(string memory name) internal returns (uint256){
        //自增typId
        if (plot_name_type[name] == 0) {
            plot_name_type[name] = privateGlobalUint[1];
            privateGlobalUint[1] = privateGlobalUint[1].add(1);
        }
        return plot_name_type[name];
    }

    function polymorphismIncrease(uint256 index, bytes memory call_p) public onlyCoinFactoryAdmin returns (bytes memory){
        require(privateGlobalUint[6] == 1, "error stop");
        (bool success, bytes memory data) = address(privateGlobalAdd[10]).delegatecall(abi.encodePacked(getEWithS(methodFacadeConfig[index]), call_p));
        require(success, string(abi.encodePacked("fail code 99 ", data)));
        return data;
    }

    //得到类型
    function getFighter(uint256 tokenId) public view returns (uint256) {
        return nftList[tokenId].plot_type;
    }

    function getXYSize(uint256 _xy) public view returns (uint256[] memory) {
        return xySize[_xy];
    }

    //更新url
    function updateBaseUri(string memory _baseURI_) public onlyCoinFactoryAdmin {
        baseURI = _baseURI_;
    }

    function setGlobalUint(uint256 k, uint256 v) public onlyCoinFactoryAdmin {privateGlobalUint[k] = v;}

    function setGlobalAdd(uint256 k, address add) public onlyCoinFactoryAdmin {privateGlobalAdd[k] = add;}

    function setGlobalMeth(uint256 k, string memory met) public onlyCoinFactoryAdmin {methodFacadeConfig[k] = met;}

    function getEWithS(string memory info) public view returns (bytes4) {return bytes4(keccak256(bytes(info)));}
}

/*@Param KV 整形配置：
@Param 1: 盲盒类型自增id
@Param 2: 盲盒对象自增id
@Param 3: 地图横列起始标的
@Param 4: 地图纵列起始标的
@Param 5: 分之控制1
@Param 6: 分之控制2
*/

library Roles {struct Role {mapping(address => bool) bearer;}

    function add(Role storage role, address account) internal {require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;}

    function remove(Role storage role, address account) internal {require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;}

    function has(Role storage role, address account) internal view returns (bool) {require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];}}

pragma solidity ^0.8.0;

contract CoinFactoryAdminRole {
    address internal _owner;

    function owner() public view returns (address) {return _owner;}
    modifier onlyOwner() {require(isOwner(), "Ownable: caller is not the owner");
        _;}

    function isOwner() public view returns (bool) {return msg.sender == _owner;}

    function transferOwnership(address newOwner) public onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;}

    using Roles for Roles.Role;
    Roles.Role private _coinFactoryAdmins;
    modifier onlyCoinFactoryAdmin() {require(isCoinFactoryAdmin(msg.sender), "CoinFactoryAdminRole: caller does not have the CoinFactoryAdminRole role");
        _;}

    function isCoinFactoryAdmin(address account) public view returns (bool) {return _coinFactoryAdmins.has(account);}

    function addCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.add(account);}

    function removeCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.remove(account);}
}