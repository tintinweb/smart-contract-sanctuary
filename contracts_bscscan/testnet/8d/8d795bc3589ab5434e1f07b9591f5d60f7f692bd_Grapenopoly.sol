/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract ERC20 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Grapenopoly
{
    struct PropertyModel {
        uint256 id;
        string name;
        string description;
        string imageURI;
        uint256 price;
        uint state;
        uint zone;
        uint[] rent;
        uint256 mortgage;
    }

    // NFT Properties
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02; //https://eips.ethereum.org/EIPS/eip-721
    uint256 public id;
    mapping(bytes4 => bool) public supportsInterface; // ERC-165
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public nftOwners;
    mapping(uint256 => address) public approvedOperator;
    mapping(address => mapping(address => bool)) public approvedForAll;

    // NFT Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Game Properties
    address public networkcoinaddress;
    address public owner;
    uint public totalDices;
    uint public diceFaces;
    uint diceNonce;
    uint256 MAX_DICE_NONCE;
    string public nftURI;
    uint public maxHouseAmount;

    mapping(uint256 => string) public nftName;
    mapping(uint256 => string) public nftDescription;
    mapping(uint256 => string) public nftImageURI;
    mapping(uint256 => uint256) public nftPrice;
    mapping(uint256 => uint) public nftState;
    mapping(uint256 => uint) public nftZone;
    mapping(uint256 => mapping(uint => uint256)) public nftRent;
    mapping(uint256 => uint) public nftMortgage;

    //Min Deposit for each Token
    mapping(address => uint256) public minDeposit;

    //Min Withdraw for each Token
    mapping(address => uint256) public minWithdraw;

    //User lists (1st mapping user, 2nd mapping token)
    mapping(address => mapping(address => uint256)) vaultBalances;

    //Game Events
    event OnDeposit(address from, address token, uint256 total);
    event OnWithdraw(address to, address token, uint256 total);

    constructor()
    {
        //NFT Startup Attributes
        supportsInterface[0x80ac58cd] = true; // ERC-721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x01ffc9a7] = true; // EIP-165

        //Game Startup Attributes
        owner = msg.sender;
        networkcoinaddress = address(0x1110000000000000000100000000000000000111);
        totalDices = 3;
        diceFaces = 6;
        diceNonce = 0;
        MAX_DICE_NONCE = 237512;
        maxHouseAmount = 4;
        nftURI = "https://grapestaking.lidia.in/nft-info/";
    }

    // **********************************************
    // *************** GAME FUNCTIONS ***************
    // **********************************************
    function depositToken(ERC20 token, uint256 amountInWei) external 
    {
        address tokenAddress = address(token);

        //Approve (outside): allowed[msg.sender][spender] (sender = my account, spender = token address)
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amountInWei, "AL"); //VAULT: Check the token allowance. Use approve function.

        require(amountInWei >= minDeposit[address(token)], "DL"); //VAULT: Deposit value is too low.

        token.transferFrom(msg.sender, address(this), amountInWei);

        uint256 currentTotal = vaultBalances[msg.sender][tokenAddress];

        //Increase/register deposit balance
        vaultBalances[msg.sender][tokenAddress] = safeAdd(currentTotal, amountInWei);

        emit OnDeposit(msg.sender, tokenAddress, amountInWei);
    }

    function depositNetworkCoin() external payable 
    {
        require(msg.value > 0, "DL"); //VAULT: Deposit value is too low.

        require(msg.value >= minDeposit[networkcoinaddress], "DL"); //VAULT: Deposit value is too low.

        uint256 currentTotal = vaultBalances[msg.sender][networkcoinaddress];

        //Increase/register deposit balance
        vaultBalances[msg.sender][networkcoinaddress] = safeAdd(currentTotal, msg.value);

        emit OnDeposit(msg.sender, networkcoinaddress, msg.value);
    }

    function withdraw(address token, uint256 amountInWei) external
    {
        systemWithdraw(msg.sender, token, amountInWei, 0);
    }

    function forcePlayerWithdraw(address player, address token, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        systemWithdraw(player, token, amountInWei, 0);
    }

    function forceSystemWithdraw(address toAddress, address token, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        systemWithdraw(toAddress, token, amountInWei, 1);
    }

    function systemWithdraw(address player, address token, uint256 amountInWei, uint dontChangeBalances) internal 
    {
        require(amountInWei >= minWithdraw[token], "WL"); //VAULT: Withdraw value is too low.

        uint sourceBalance;
        if(address(token) != networkcoinaddress)
        {
            //Balance in Token
            sourceBalance = ERC20(token).balanceOf(address(this));
        }
        else
        {
            //Balance in Network Coin
            sourceBalance = address(this).balance;
        }

        require(sourceBalance >= amountInWei, "LW"); //VAULT: Too low reserve to withdraw the requested amount

        //Withdraw of deposit value
        if(token != networkcoinaddress)
        {
            //Withdraw token
            ERC20(token).transfer(player, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(player).transfer(amountInWei);
        }

        if(dontChangeBalances == 0)
        {
            uint256 currentTotal = vaultBalances[player][token];
            vaultBalances[player][token] = safeSub(currentTotal, amountInWei);
        }

        emit OnWithdraw(player, token, amountInWei);
    }

    function rollDices() public returns (uint[] memory)
    {
        uint[] memory result = new uint[](totalDices);

        for(uint ix = 0; ix < totalDices; ix++)
        {
            result[ix] = getDiceFace();
        }
        return result;
    }

    function getDiceFace() internal returns(uint)
    {
        uint vFace = uint(keccak256(abi.encodePacked(
            safeAdd(block.timestamp, diceNonce), 
            block.difficulty, 
            msg.sender)
        )) % diceFaces;

        if(safeAdd(diceNonce, 1) >= MAX_DICE_NONCE)
        {
            diceNonce = 0;
        }
        
        diceNonce++;

        return vFace;
    }

    //Get Attribute Values
    function getPlayerBalance(address player, address token) external view returns (uint256 value)
    {
        return vaultBalances[player][token];
    }

    function getPropertyList() external view returns (PropertyModel[] memory)
    {
        PropertyModel[] memory result = new PropertyModel[](id);

        if(id > 0)
        {
            uint[] memory rent = new uint[](maxHouseAmount + 2);

            for(uint idRead = 1; idRead <= id; idRead++)
            {
                for(uint ixRent = 0; ixRent <= maxHouseAmount + 1; ixRent++)
                {
                    rent[ixRent] = nftRent[idRead][ixRent]; //First is no house and last is hotel
                }

                result[idRead - 1] = PropertyModel({
                    id: idRead,
                    name: nftName[idRead],
                    description: nftDescription[idRead],
                    imageURI: nftImageURI[idRead],
                    price: nftPrice[idRead],
                    state: nftState[idRead],
                    zone: nftZone[idRead],
                    rent: rent,
                    mortgage: nftMortgage[idRead]
                });
            }
        }

        return result;
    }

    //Set Attribute Values
    function setOwner(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        owner = newValue;
        return true;
    }

    function setMinDeposit(address token, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minDeposit[token] = value;
        return true;
    }

    function setMinWithdraw(address token, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minWithdraw[token] = value;
        return true;
    }

    function setNFTURI(string memory newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftURI = newValue;
        return true;
    }

    function setMaxHouseAmount(uint newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        maxHouseAmount = newValue;
        return true;
    }

    function setNetworkCoinAddress(address newValue) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        networkcoinaddress = newValue;
        return true;
    }

    function setTotalDices(uint value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        totalDices = value;
        return true;
    }

    function setDiceFaces(uint value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        diceFaces = value;
        return true;
    }

    // ***********************************************
    // **************** NFT FUNCTIONS ****************
    // ***********************************************
    //function mint(string calldata _uri) external returns (uint256 tokenId)
    function mint(string calldata _nftName, string calldata _nftDescription, string calldata _nftImageURI, uint256 _nftPrice, uint _nftZone) external returns (uint256 tokenId)
    {
        //Only contract owner is able to create properties
        require(msg.sender == owner, 'FN'); //Forbidden

        id = safeAdd(id, 1); //id++
        nftOwners[id] = msg.sender;
        nftName[id] = _nftName;
        nftDescription[id] = _nftDescription;
        nftImageURI[id] = _nftImageURI;
        nftPrice[id] = _nftPrice;
        nftZone[id] = _nftZone;
        nftState[id] = 1;
        
        for(uint ixRent = 0; ixRent <= maxHouseAmount + 1; ixRent++) //First is no house and last is hotel
        {
            nftRent[id][ixRent] = safeMul(safeDiv(_nftPrice, 100), safeAdd(ixRent, 1)) ; 
        }

        nftMortgage[id] = safeDiv(_nftPrice, 2);

        balances[msg.sender] = safeAdd(balances[msg.sender], 1); //balances[msg.sender]++;
        
        emit Transfer(address(0), msg.sender, id);

        return id;
    }

    function bulkMint(string[] calldata _nftName, string[] calldata _nftDescription, string[] calldata _nftImageURI, uint256[] calldata _nftPrice, uint[] calldata _nftZone) external
    {
        //Only contract owner is able to create properties
        require(msg.sender == owner, 'FN'); //Forbidden

        require(_nftName.length > 0, "Empty list");
        require(_nftName.length == _nftDescription.length && _nftName.length == _nftImageURI.length && _nftName.length == _nftPrice.length, "Invalid Size");

        for(uint ix = 0; ix < _nftName.length; ix++)
        {
            id = safeAdd(id, 1); //id++
            nftOwners[id] = msg.sender;
            nftName[id] = _nftName[ix];
            nftDescription[id] = _nftDescription[ix];
            nftImageURI[id] = _nftImageURI[ix];
            nftPrice[id] = _nftPrice[ix];
            nftState[id] = 1;
            nftZone[id] = _nftZone[ix];

            for(uint ixRent = 0; ixRent <= maxHouseAmount + 1; ixRent++) //First is no house and last is hotel
            {
                nftRent[id][ixRent] = safeMul(safeDiv(_nftPrice[ix], 100), safeAdd(ixRent, 1)) ; 
            }

            nftMortgage[id] = safeDiv(_nftPrice[ix], 2);

            balances[msg.sender] = safeAdd(balances[msg.sender], 1); //balances[msg.sender]++;
            
            emit Transfer(address(0), msg.sender, id);
        }
    }

    function name() external pure returns (string memory _name) 
    {
        return "Grapenopoly Property";
    }
    
    function symbol() external pure returns (string memory _symbol) 
    {
        return "GRAPEPPT";
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) 
    {
        require(_tokenId <= id, "Invalid NFT ID");
        return strConcatenate(strConcatenate(strConcatenate(strConcatenate(nftURI, uint2str(block.chainid)), "/"), uint2str(_tokenId)), ".json");
    }

    function balanceOf(address _owner) external view returns (uint256)
    {
        require(_owner != address(0), "Zero address is not allowed");
        return balances[_owner];    
    }

    function ownerOf(uint256 _tokenId) external view returns (address)
    {
        return nftOwners[_tokenId];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external
    {
        require(nftOwners[_tokenId] == _from, "Invalid NFT owner");
        require(msg.sender == _from || msg.sender == approvedOperator[_tokenId] || approvedForAll[_from][msg.sender] == true, "Not authorized");
        
        _transfer(_from, _to, _tokenId); 
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external
    {
        require(nftOwners[_tokenId] == _from, "Invalid NFT owner");
        require(msg.sender == _from || msg.sender == approvedOperator[_tokenId] || approvedForAll[_from][msg.sender] == true, "Not authorized");
        
        _transfer(_from, _to, _tokenId); 
        
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "Transfer to non ERC721Receiver implementer");
    }

    function approve(address _to, uint256 _tokenId) external
    {
        address ownerAddr = nftOwners[_tokenId];
        require(msg.sender == owner || approvedForAll[ownerAddr][msg.sender] == true, "Not authorized"); 
        approvedOperator[_tokenId] = _to;
        emit Approval(ownerAddr, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address)
    {
        return approvedOperator[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external
    {
        approvedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return approvedForAll[_owner][_operator];
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool)
    {
        //return true;
        if (!isContract(_to)) 
        {
            return true;
        }

        bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal
    {
        balances[_from] = safeSub(balances[_from], 1); //balances[_from]--
        balances[_to] = safeAdd(balances[_to], 1); //balances[_to]++;
        nftOwners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function setNFTName(uint256 _tokenId, string calldata value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftName[_tokenId] = value;
        return true;
    }

    function setNFTDescription(uint256 _tokenId, string calldata value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftDescription[_tokenId] = value;
        return true;
    }

    function setNFTImageURI(uint256 _tokenId, string calldata value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftImageURI[_tokenId] = value;
        return true;
    }

    function setNFTPrice(uint256 _tokenId, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftPrice[_tokenId] = value;
        return true;
    }

    function setNFTState(uint256 _tokenId, uint value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftState[_tokenId] = value;
        return true;
    }

    function setNFTZone(uint256 _tokenId, uint value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftZone[_tokenId] = value;
        return true;
    }

    function setNFTRent(uint256 _tokenId, uint rentIndex, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(rentIndex < maxHouseAmount + 1, 'IX'); //Invalid Index
        nftRent[_tokenId][rentIndex] = value;
        return true;
    }

    function setNFTMortgage(uint256 _tokenId, uint256 value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftMortgage[_tokenId] = value;
        return true;
    }

    // Returns whether the target address is a contract
    function isContract(address account) internal view returns (bool) 
    {
        uint256 size;
        // Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // ****************************************************
    // ***************** HELPER FUNCTIONS *****************
    // ****************************************************
    function strConcatenate(string memory s1, string memory s2) internal pure returns (string memory) 
    {
        return string(abi.encodePacked(s1, s2));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) 
    {
        if (_i == 0) 
        {
            return "0";
        }

        uint j = _i;
        uint len;

        while (j != 0) 
        {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint k = len;

        while (_i != 0) 
        {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }

    // *****************************************************
    // **************** SAFE MATH FUNCTIONS ****************
    // *****************************************************
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "OADD"); //STAKE: SafeMath: addition overflow

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeSub(a, b, "OSUB"); //STAKE: subtraction overflow
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "OMUL"); //STAKE: multiplication overflow

        return c;
    }

    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = safeDiv(safeMul(a, b), safePow(10, uint256(decimals)));

        return result;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {

        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  safeDiv(e, 2));
            p = safeMul(p, p);

            if (safeMod(e, 2) == 1) 
            {
                p = safeMul(p, n);
            }

            return p;
        }
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeDiv(a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeDiv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeMod(a, b, "ZMOD"); //STAKE: modulo by zero
    }

    function safeMod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}