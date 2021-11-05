// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";


interface Common1155NFT{
    function mint(address account, uint256 id, uint256 amount, bytes memory data)external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)external;
    function burn(address account, uint256 id, uint256 amount) external;
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function dissolve(address account, uint256 id, uint256 value)external;
    function dissolveBatch(address account, uint256[] memory ids, uint256[] memory values)external;
}


interface Common721NFT{
    function mint(address account, uint256 id)external;
    function exists(uint256 tokenId) external view returns (bool);
    function burn(uint256 tokenId) external;
    function balanceOf(address owner) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}


contract LotteryV1 is AccessControl, Pausable {

    /* Variable */
    using SafeMath for uint256;
    uint256 internal eventId = 1;
    address internal signerAddress;//签名钱包地址
    address internal assetsContractAddress;//资产合约地址
    address internal ticketContractAddress;//奖券合约地址
    uint256 internal ticketPrice;//奖券价格
    uint256 internal eventTokenIdRange;//场次TokenId范围
    mapping (uint256 => EventInfo) internal EventInfoMap;
    bytes32 public constant EVENT_CREATE_ROLE = keccak256("EVENT_CREATE_ROLE");
    bytes32 public constant ETH_TRANSFER_ROLE = keccak256("ETH_TRANSFER_ROLE");


    //Interface Signature ERC1155 and ERC721
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;

    constructor (uint256 _ticketPrice,uint256 _eventTokenIdRange,address _assetsContractAddress,address _ticketContractAddress){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EVENT_CREATE_ROLE, msg.sender);
        _setupRole(ETH_TRANSFER_ROLE, msg.sender);
        assetsContractAddress = _assetsContractAddress;
        ticketContractAddress = _ticketContractAddress;
        ticketPrice = _ticketPrice;
        eventTokenIdRange = _eventTokenIdRange;
        signerAddress = msg.sender;
    }

    struct EventInfo{
        uint256 ethPrice;
        uint256 NFTNumber;
        uint256 ticketNumber;
        uint256 startTokenId;
        uint256 purchasedNumber;
        address NFTContractAddress;
        bool status;
    }

    /* Event */
    event ETHReceived(address sender, uint256 value);
    event Raffle(uint256 indexed eventId,address indexed buyer,uint256 indexed amount, uint256 ticketNumber,uint256 payType,uint256[] nftTokenIds,string nonce);
    event WithdrawNFT(uint256 indexed _tokenId,address indexed _withdrawNFTContractAddress,uint256 indexed _withdrawNFTTokenID,address _withdrawNFTAddress,address _withdrawNFT2Address,string nonce);
    event WithdrawNFTByMint(uint256 indexed _tokenId,address indexed _withdrawNFTContractAddress,uint256 indexed _withdrawNFTTokenID,address _mintNFTAddress,string nonce);
    event BathConvertNFT(uint256 indexed _amount,address indexed _from,string indexed _convertType,uint256[] _tokenIds,string nonce);
    event ConvertNFT(uint256 indexed _tokenId,uint256 indexed _amount,address indexed _from,string nonce ,string _convertType);


    //Fallback function
    fallback() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    //Receive function
    receive() external payable {
        // TODO implementation the receive function
    }

    /**
     * @dev  创建场次
     * @param _ethPrice   本场次设置的eth价格
     * @param _NFTNumber  奖池数量
     * @param _NFTContractAddress 奖品NFT合约地址
     */
    function createEvent(uint256 _ethPrice ,uint256 _NFTNumber,address _NFTContractAddress) public{
        //鉴权
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        //判断要设置的NFTNumber是否合法，max--1000
        require((_NFTNumber >0) && (_NFTNumber <= 1000),"The NFTNumber is invalid!" );
        //记录本场次的详细信息
        EventInfoMap[eventId].ethPrice = _ethPrice;
        EventInfoMap[eventId].NFTNumber = _NFTNumber;
        EventInfoMap[eventId].NFTContractAddress = _NFTContractAddress;
        //场次默认关闭
        EventInfoMap[eventId].status = false;
        EventInfoMap[eventId].startTokenId = eventId.mul(eventTokenIdRange);
        //场次自增
        eventId ++;
    }

    /**
     * @dev  设置资产合约地址
     * @param _assetsContractAddress 新的资产合约地址
     */
    function setAssetsContractAddress(address _assetsContractAddress)public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        assetsContractAddress = _assetsContractAddress;
    }

    /**
     * @dev  设置NFT合约地址
     * @param _NFTContractAddress 新的NFT合约地址
     * @param _eventId 场次ID
     */
    function setNFTContractAddress(uint256 _eventId,address _NFTContractAddress)public{
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        EventInfoMap[_eventId].NFTContractAddress = _NFTContractAddress;
    }

    /**
     * @dev  设置签名钱包地址
     * @param _signerAddress 新的签名钱包地址
     */
    function setSignerAddress(address _signerAddress)public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        signerAddress = _signerAddress;
    }

    /**
     * @dev  设置奖券合约地址
     * @param _ticketContractAddress 新的奖券合约地址
     */
    function setTicketContractAddress(address _ticketContractAddress)public{
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        ticketContractAddress = _ticketContractAddress;
    }

    /**
    * @dev  设置奖券价格
     * @param _ticketPrice 新的奖券价格
     */
    function setTicketPrice(uint256 _ticketPrice)public{
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        ticketPrice = _ticketPrice;
    }


    /**
     * @dev  设置场次购买价格
     * @param _eventId 场次ID
     * @param _ethPrice 新的场次购买价格
     */
    function setEthPrice(uint256 _eventId,uint256 _ethPrice)public{
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        EventInfoMap[_eventId].ethPrice = _ethPrice;
    }

    /**
     * @dev  设置场次奖池数量
     * @param _eventId 场次ID
     * @param _NFTNumber 新的场次奖池数量
     */
    function setNFTNumber(uint256 _eventId,uint256 _NFTNumber)public{
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        require((_NFTNumber >0) && (_NFTNumber <= 1000),"The NFTNumber is invalid!" );
        EventInfoMap[_eventId].NFTNumber = _NFTNumber;
    }

    /**
     * @dev  暂停该场次
     * @param _eventId 场次ID
     */
    function stopEvent(uint256 _eventId)public{
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        EventInfoMap[_eventId].status = false;
    }

    /**
     * @dev  启动该场次
     * @param _eventId 场次ID
     */
    function startEvent(uint256 _eventId)public{
        require(hasRole(EVENT_CREATE_ROLE, msg.sender));
        EventInfoMap[_eventId].status = true;
    }

    /**
     * @dev  全部抽奖
     * @param _eventId 场次ID
     * @param _payType 支付方式 1---eth支付；2---全用代金券支付；3---部分支付，优先使用代金券支付
     * @param hash 交易hash
     * @param signature 交易签名
     * @param nonce 交易随机数
     */
    function raffleAll(uint256 _eventId,uint256 _payType,bytes32 hash, bytes memory signature,string memory nonce)public payable whenNotPaused{
        _raffle(_eventId,0,_payType,hash,signature,nonce);
    }

    /**
     * @dev  部分抽奖
     * @param _eventId 场次ID
     * @param _amount 要抽的奖品数量
     * @param _payType 支付方式 1---eth支付；2---全用代金券支付；3---部分支付，优先使用代金券支付
     * @param hash 交易hash
     * @param signature 账户签名
     * @param nonce 交易随机数
     */
    function raffle(uint256 _eventId,uint256 _amount,uint256 _payType,bytes32 hash, bytes memory signature,string memory nonce)public payable whenNotPaused{
        _raffle(_eventId,_amount,_payType,hash,signature,nonce);
    }

    /**
     * @dev  抽奖内部封装函数
     * @param _eventId 场次ID
     * @param _amount 要抽的奖品数量  全部抽奖为0
     * @param _payType 支付方式 1---eth支付；2---全用代金券支付；3---部分支付，优先使用代金券支付
     * @param hash 交易hash
     * @param signature 账户签名
     * @param nonce 交易随机数
     */
    function _raffle(uint256 _eventId,uint256 _amount,uint256 _payType,bytes32 hash, bytes memory signature,string memory nonce)internal {
        uint256 EventId = _eventId;
        string  memory Nonce = nonce;
        uint256 amount = _amount;
        //判断场次是否开启
        assert(EventInfoMap[EventId].status);
        //计算剩余的NFT数量
        uint256 subNFTNumber = EventInfoMap[EventId].NFTNumber.sub(EventInfoMap[EventId].purchasedNumber);
        //若_amount==0 则为全部抽奖
        if (amount == 0){
            amount = subNFTNumber;
        }
        //判断要参与抽奖的NFT数量是否合法
        require((amount > 0) && (amount <= subNFTNumber),"The amount of Raffle-NFT is insufficient!");
        //验证hash
        require(hashRaffleTransaction(EventId,msg.sender,amount,nonce,_payType) == hash,"Invalid hash!");
        //验证签名
        require(matchAddresSigner(hash,signature),"Invalid signature!");
        //计算参与抽奖的NFT总eth价值
        uint256 totalPrice = amount.mul(EventInfoMap[_eventId].ethPrice);
        //生成需铸造的TokenIdArray.
        uint256[] memory mintNftTokenIds = _getNftTokenIds(_eventId,amount);
        address NFTContractAddress;
        //判断是否已经设置了NFT合约地址
        //如果没有设置合约地址 则将全局
        //资产合约地址变量赋值给NFT地址。
        if (EventInfoMap[_eventId].NFTContractAddress == address(0)){
            NFTContractAddress = assetsContractAddress;
        }else{
            NFTContractAddress = EventInfoMap[_eventId].NFTContractAddress;
        }
        //判断支付方式 1---eth支付；2---全用代金券支付；3---部分支付，优先使用代金券支付
        if (_payType == 1){
            require(msg.value >= totalPrice,"The ether of be sent must be more than the totalprice!");
            require(_mintNft(mintNftTokenIds,1,NFTContractAddress),"NFT mint failed");
            payable(address(this)).transfer(totalPrice);
            if (msg.value > totalPrice){
                payable(msg.sender).transfer(msg.value - totalPrice);
            }
            emit Raffle(EventId,msg.sender,amount,0,1,mintNftTokenIds,Nonce);
        }else{
            //查询拥有的奖券
            Common1155NFT ticketContract = Common1155NFT(ticketContractAddress);
            //拥有的奖券数量
            uint256 ticketNumber = ticketContract.balanceOf(msg.sender,1);
            //若全部购买要消耗掉的奖券数量
            uint256 burnTicketNumber = totalPrice.div(ticketPrice);
            //用代金券支付
            if (_payType == 2){
                require(ticketNumber >= burnTicketNumber,"The tickets are insufficient!");
                require(_mintNft(mintNftTokenIds,1,NFTContractAddress),"NFT mint failed");
                _burnNFT(ticketContractAddress,1,burnTicketNumber);
                emit Raffle(EventId,msg.sender,amount,burnTicketNumber,2,mintNftTokenIds,Nonce);
            }
            //混合支付
            if (_payType == 3){
                //优先使用代金券支付，当代金券可以完全支付时
                if (ticketNumber >= burnTicketNumber){
                    require(_mintNft(mintNftTokenIds,1,NFTContractAddress),"NFT mint failed");
                    ticketContract.burn(msg.sender,1,burnTicketNumber);
                    emit Raffle(EventId,msg.sender,amount,burnTicketNumber,3,mintNftTokenIds,Nonce);
                }else{
                    string memory _Nonce = Nonce;
                    uint256 _EventId = EventId;
                    //优先使用代金券支付，当代金券不足时，使用eth抵扣
                    //计算差额代金券
                    uint256 subTicketNumber = burnTicketNumber.sub(ticketNumber);
                    //计算扣除代金券需另支付的eth
                    uint256 subTicketAmount = subTicketNumber.mul(ticketPrice);
                    require(msg.value >= subTicketAmount,"The ether of be sent must be more than the subTicketAmount!");
                    require(_mintNft(mintNftTokenIds,1,NFTContractAddress),"NFT mint failed!");
                    require(_burnNFT(ticketContractAddress,1,ticketNumber),"burnNFT failed!");
                    payable(address(this)).transfer(subTicketAmount);
                    if (msg.value > subTicketAmount){
                        payable(msg.sender).transfer(msg.value - subTicketAmount);
                    }
                    emit Raffle(_EventId,msg.sender,amount,burnTicketNumber,3,mintNftTokenIds,_Nonce);
                }
            }
        }
        //增加该场次的已购买的NFT数量
        EventInfoMap[EventId].purchasedNumber += amount;
    }

    /**
     * @dev  生成本场次要铸造的TokenIdsArray
     * @param _eventId 场次ID
     * @param _arrayLength 要铸造的TokenId数量
     * @return 将要铸造的TokenIdsArray
     */
    function _getNftTokenIds(uint256 _eventId,uint256 _arrayLength) internal view returns(uint256[] memory){
        uint256[] memory resultNftTokenIds = new uint256[](_arrayLength);
        uint256 startTokenId = EventInfoMap[_eventId].startTokenId.add(EventInfoMap[_eventId].purchasedNumber);
        for (uint256 i = 0; i < _arrayLength; i++) {
            resultNftTokenIds[i] = startTokenId + i;
        }
        return resultNftTokenIds;
    }

    /**
     * @dev  铸造nft内部封装方法
     * @param _mintNftTokenIds 将要铸造的TokenIdsArray
     * @param _mintAmount 每个id铸造的数量
     * @param _ContractAddress 铸造的合约地址
     * @return 是否铸造成功
     */
    //铸造NFT
    function _mintNft(uint256[] memory _mintNftTokenIds,uint256 _mintAmount,address _ContractAddress)internal returns(bool) {
        if (_checkProtocol(_ContractAddress) == 1){
            Common1155NFT Common1155NFTContract = Common1155NFT(_ContractAddress);
            if (_mintNftTokenIds.length == 1){
                Common1155NFTContract.mint(msg.sender,_mintNftTokenIds[0],_mintAmount,abi.encode(msg.sender));
            }else{
                uint256[] memory amountArray = _generateAmountArray(_mintNftTokenIds.length);
                Common1155NFTContract.mintBatch(msg.sender,_mintNftTokenIds,amountArray,abi.encode(msg.sender));
            }
            return true;
        }
        if(_checkProtocol(_ContractAddress) == 2){
            Common721NFT Common721NFTContract = Common721NFT(_ContractAddress);
            for (uint256 i = 0; i < _mintNftTokenIds.length; i++) {
                Common721NFTContract.mint(msg.sender,_mintNftTokenIds[i]);
            }
            return true;
        }
        return false;
    }

    /**
     * @dev  生成批量铸造时铸造数量AmountArray
     * @param _arrayLength 要铸造的TokenId数量
     * @return 铸造数量AmountArray
     */
    function _generateAmountArray(uint256 _arrayLength) internal  pure returns(uint256 [] memory){
        uint256[] memory amountArray = new uint256[](_arrayLength);
        for (uint256 i = 0; i < _arrayLength; i++) {
            amountArray[i] = 1;
        }
        return amountArray;
    }

     /**
     * @dev  提现奖品兑换成指定的NFT
     * @param _tokenId 被兑换的奖品TokenId
     * @param _withdrawNFTContractAddress 要被兑换的NFT合约地址
     * @param _withdrawNFTTokenID 要被兑换的NFT的TokenId
     * @param hash 交易hash
     * @param signature 交易签名
     * @param nonce 交易随机数
     */
    function withdrawNFTByMint(uint256 _tokenId,address _withdrawNFTContractAddress,uint256 _withdrawNFTTokenID,bytes32 hash, bytes memory signature,string memory nonce)public whenNotPaused{
        //验证hash
        require(hashwithdrawNFTByMintTransaction(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,msg.sender,nonce) == hash,"Invalid hash!");
        //验证签名
        require(matchAddresSigner(hash,signature),"Invalid signature!");
        //验证是否拥有该资产NFT
        require(_validateOwnership(_tokenId),"You don't have this NFT!");
        //转移NFT
        if (_checkProtocol(_withdrawNFTContractAddress) == 1){
            Common1155NFT withdrawNFTContract = Common1155NFT(_withdrawNFTContractAddress);
//            assert(withdrawNFTContract.balanceOf(msg.sender,_withdrawNFTTokenID) >0);
            withdrawNFTContract.mint(msg.sender,_withdrawNFTTokenID,1,abi.encode(msg.sender));
            require(_burnNFT(assetsContractAddress,_tokenId,1));
            emit WithdrawNFTByMint(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,msg.sender,nonce);
        }
        if (_checkProtocol(_withdrawNFTContractAddress) == 2){
            Common721NFT withdrawNFTContract = Common721NFT(_withdrawNFTContractAddress);
//            assert(withdrawNFTContract.ownerOf(_withdrawNFTTokenID) != msg.sender);
            withdrawNFTContract.mint(msg.sender,_withdrawNFTTokenID);
            require(_burnNFT(assetsContractAddress,_tokenId,1));
            emit WithdrawNFTByMint(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,msg.sender,nonce);
        }
    }

    /**
     * @dev  提现奖品兑换成指定的NFT
     * @param _tokenId 被兑换的奖品TokenId
     * @param _withdrawNFTContractAddress 要被兑换的NFT合约地址
     * @param _withdrawNFTTokenID 要被兑换的NFT的TokenId
     * @param _withdrawNFTAddress 要被兑换的NFT钱包地址
     * @param hash 交易hash
     * @param signature 交易签名
     * @param nonce 交易随机数
     */
    function withdrawNFT(uint256 _tokenId,address _withdrawNFTContractAddress,uint256 _withdrawNFTTokenID,address _withdrawNFTAddress,bytes32 hash, bytes memory signature,string memory nonce)public whenNotPaused{
        //验证hash
        require(hashWithdrawNFTTransaction(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,_withdrawNFTAddress,msg.sender,nonce) == hash,"Invalid hash!");
        //验证签名
        require(matchAddresSigner(hash,signature),"Invalid signature!");
        //验证是否拥有该资产NFT
        require(_validateOwnership(_tokenId),"You don't have this NFT!");
        //转移NFT
        if (_checkProtocol(_withdrawNFTContractAddress) == 1){
            ERC1155 withdrawNFTContract = ERC1155(_withdrawNFTContractAddress);
            withdrawNFTContract.safeTransferFrom(_withdrawNFTAddress,msg.sender,_withdrawNFTTokenID,1,abi.encode(msg.sender));
            require(_burnNFT(assetsContractAddress,_tokenId,1));
            emit WithdrawNFT(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,_withdrawNFTAddress,msg.sender,nonce);
        }
        if (_checkProtocol(_withdrawNFTContractAddress) == 2){
            ERC721 withdrawNFTContract = ERC721(_withdrawNFTContractAddress);
            withdrawNFTContract.safeTransferFrom(_withdrawNFTAddress,msg.sender,_withdrawNFTTokenID);
            require(_burnNFT(assetsContractAddress,_tokenId,1));
            emit WithdrawNFT(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,_withdrawNFTAddress,msg.sender,nonce);
        }
    }

    /**
     * @dev 判断合约类型 1----ERC1155;  2----ERC721
     * @param _contractAddress 合约地址
     * @return 合约类型
     */
    function _checkProtocol(address _contractAddress)internal view returns(uint256){
        IERC165 Contract = IERC165(_contractAddress);
        if (Contract.supportsInterface(INTERFACE_SIGNATURE_ERC1155)){
            //1---ERC1155
            return 1;
        }
        if (Contract.supportsInterface(INTERFACE_SIGNATURE_ERC721)){
            //2---ERC721
            return 2;
        }
        revert("Invalid contract protocol!");
    }

     /**
     * @dev 兑换奖品为eth
     * @param _tokenId 奖品tokenId
     * @param _ETHAmount 想要兑换的eth数量
     * @param hash 交易hash
     * @param signature 账户签名
     * @param nonce 交易随机数
     */
    function convertNFT2ETH(uint256 _tokenId,uint256 _ETHAmount ,bytes32 hash, bytes memory signature,string memory nonce)public payable whenNotPaused{
        //验证hash
        require(hashConvertNFTTransaction(_tokenId,msg.sender,_ETHAmount,nonce,"ETH") == hash,"Invalid hash!");
        //验证签名
        require(matchAddresSigner(hash,signature),"Invalid signature!");
        //验证是否拥有该资产NFT
        require(_validateOwnership(_tokenId),"You don't have this NFT!");
        payable(msg.sender).transfer(_ETHAmount);
        //销毁奖品
        require(_burnNFT(assetsContractAddress,_tokenId,1),"burnNFT failed!");
        emit ConvertNFT(_tokenId,_ETHAmount,msg.sender,nonce,"ETH");
    }

    /**
     * @dev 批量兑换奖品为eth
     * @param _tokenIdArray 奖品tokenId数组
     * @param _ETHAmount 想要兑换的eth数量
     * @param hash 交易hash
     * @param signature 交易签名
     * @param nonce 交易随机数
     */
    function bathConvertNFT2ETH(uint256[] memory _tokenIdArray,uint256 _ETHAmount ,bytes32 hash, bytes memory signature,string memory nonce)public payable whenNotPaused{
        //验证hash
        require(hashBathConvertNFTsTransaction(_tokenIdArray,msg.sender,_ETHAmount,nonce,"ETH") == hash,"Invalid hash!");
        //验证签名
        require(matchAddresSigner(hash,signature),"Invalid signature!");
        //验证是否拥有该资产NFT
        require(_bathValidateOwnership(_tokenIdArray),"You don't have these NFT!");
        //        require(_ETHAmount >= ticketPrice);
        payable(msg.sender).transfer(_ETHAmount);
        //销毁奖品
        require(_bathBurnNFT(_tokenIdArray),"burnNFT failed!");
        emit BathConvertNFT(_ETHAmount,msg.sender,"ETH",_tokenIdArray,nonce);
    }

    /**
     * @dev 兑换奖品成奖券
     * @param _tokenId 奖品tokenId
     * @param _ticketAmount 想要兑换的奖券数量
     * @param hash 交易hash
     * @param signature 账户签名
     * @param nonce 交易随机数
     */
    function convertNFT2Ticket(uint256 _tokenId,uint256 _ticketAmount ,bytes32 hash, bytes memory signature,string memory nonce)public whenNotPaused{
        //验证hash
        require(hashConvertNFTTransaction(_tokenId,msg.sender,_ticketAmount,nonce,"Ticket") == hash,"Invalid hash!");
        //验证签名
        require(matchAddresSigner(hash,signature),"Invalid signature!");
        //验证是否拥有该资产NFT
        require(_validateOwnership(_tokenId),"You don't have this NFT!");
//        //查询要抵押的tokenId的eth价格
//        uint256 tokenPrice = EventInfoMap[_tokenId.div(eventTokenIdRange)].ethPrice;
//        //查询可以兑换的奖券数量
//        uint256 _token1Number = tokenPrice.div(ticketPrice);
//        require(_token1Number >= _token1Amount);
        uint256[] memory  a = new uint256[](1);
        a[0] = 1;
        //铸造奖券
        _mintNft(a,_ticketAmount,ticketContractAddress);
        //销毁奖品
        require(_burnNFT(assetsContractAddress,_tokenId,1),"burnNFT failed!");
        emit ConvertNFT(_tokenId,_ticketAmount,msg.sender,nonce,"Ticket");
    }

    /**
     * @dev 批量兑换奖品成奖券
     * @param _tokenIdArray 奖品tokenId数组
     * @param _ticketAmount 想要兑换的奖券数量
     * @param hash 交易hash
     * @param signature 账户签名
     * @param nonce 交易随机数
     */
    function bathConvertNFT2Ticket(uint256[] memory _tokenIdArray,uint256 _ticketAmount ,bytes32 hash, bytes memory signature,string memory nonce)public whenNotPaused{
        //验证hash
        require(hashBathConvertNFTsTransaction(_tokenIdArray,msg.sender,_ticketAmount,nonce,"Ticket") == hash,"Invalid hash!");
        //验证签名
        require(matchAddresSigner(hash,signature),"Invalid signature!");
        //批量验证是否拥有该资产NFT
        require(_bathValidateOwnership(_tokenIdArray),"You don't have these NFT!");
        //批量铸造
        _mintNft(_generateAmountArray(_tokenIdArray.length),_ticketAmount,ticketContractAddress);
        //销毁奖品
        require(_bathBurnNFT(_tokenIdArray),"burnNFT failed!");
        emit BathConvertNFT(_ticketAmount,msg.sender,"Ticket",_tokenIdArray,nonce);
    }

    /**
     * @dev 验证函数调用者是否拥有该奖品的内部封装方法
     * @param _tokenId 奖品tokenId
     * @return 是否拥有
     */
    function _validateOwnership(uint256 _tokenId)internal view returns(bool){
        IERC1155 Common1155NFTContract = IERC1155(assetsContractAddress);
        require(Common1155NFTContract.balanceOf(msg.sender,_tokenId) >0);
        return true;
    }

    /**
     * @dev 批量验证函数调用者是否拥有该奖品的内部封装方法
     * @param _tokenIdArray 奖品tokenId数组
     * @return 是否拥有
     */
    function _bathValidateOwnership(uint256[] memory _tokenIdArray)internal view returns(bool){
        IERC1155 Common1155NFTContract = IERC1155(assetsContractAddress);
        for (uint256 i = 0; i < _tokenIdArray.length; i++) {
            require(Common1155NFTContract.balanceOf(msg.sender,_tokenIdArray[i]) >0);
        }
        return true;
    }

    /**
     * @dev 要销毁的资产NFT内部封装方法
     * @param _tokenId 要销毁的tokenId
     * @param _burnNFTContractAddress 销毁的NFT合约地址
     * @param _burnNFTAmount 销毁的NFT数量
     * @return 是否销毁成功
     */
    function _burnNFT(address _burnNFTContractAddress,uint256 _tokenId,uint256 _burnNFTAmount)internal returns(bool){
        Common1155NFT Common1155NFTContract = Common1155NFT(_burnNFTContractAddress);
        Common1155NFTContract.dissolve(msg.sender,_tokenId,_burnNFTAmount);
        return true;
    }


    /**
     * @dev 批量销毁的资产NFT内部封装方法
     * @param _tokenIdArray 要销毁的tokenId数组
     * @return 是否销毁成功
     */
    function _bathBurnNFT(uint256[] memory _tokenIdArray)internal returns (bool){
        Common1155NFT Common1155NFTContract = Common1155NFT(assetsContractAddress);
        uint256[] memory burnNFTAmountArray = _generateAmountArray(_tokenIdArray.length);
        Common1155NFTContract.dissolveBatch(msg.sender,_tokenIdArray,burnNFTAmountArray);
        return true;
    }

    /**
     * @dev 生成购买交易的hash值
     * @param _eventId 场次ID
     * @param sender 交易触发者
     * @param qty 交易数量
     * @param nonce 交易随机数
     * @param _payType 支付方式
     * @return 交易的hash值
     */
    function hashRaffleTransaction(uint256 _eventId,address sender, uint256 qty, string memory nonce,uint256 _payType) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_eventId,sender,qty,nonce,_payType))
            )
        );
        return hash;
    }

    /**
     * @dev 生成提现兑换NFT交易hash
     * @param _tokenId 被兑换的奖品TokenId
     * @param _withdrawNFTContractAddress 要被兑换的NFT合约地址
     * @param _withdrawNFTTokenID 要被兑换的NFT的TokenId
     * @param _withdrawNFTAddress 要被兑换的NFT提现的钱包地址
     * @param sender 交易触发者
     * @param nonce 交易随机数
     * @return 交易的hash值
     */
    function hashWithdrawNFTTransaction(uint256 _tokenId,address _withdrawNFTContractAddress,uint256 _withdrawNFTTokenID,address _withdrawNFTAddress,address sender, string memory nonce) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,_withdrawNFTAddress,sender,nonce))
            )
        );
        return hash;
    }

    /**
     * @dev 生成提现兑换NFT交易hash
     * @param _tokenId 被兑换的奖品TokenId
     * @param _withdrawNFTContractAddress 要被兑换的NFT合约地址
     * @param _withdrawNFTTokenID 要被兑换的NFT的TokenId
     * @param sender 交易触发者
     * @param nonce 交易随机数
     * @return 交易的hash值
     */
    function hashwithdrawNFTByMintTransaction(uint256 _tokenId,address _withdrawNFTContractAddress,uint256 _withdrawNFTTokenID,address sender, string memory nonce) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_tokenId,_withdrawNFTContractAddress,_withdrawNFTTokenID,sender,nonce))
            )
        );
        return hash;
    }

    /**
     * @dev 生成抵押NFT交易的hash值
     * @param tokenId 要被抵押的奖品tokenId
     * @param sender 交易触发者
     * @param qty 交易数量
     * @param nonce 交易随机数
     * @param convertType 抵押类型
     * @return 交易的hash值
     */
    function hashConvertNFTTransaction(uint256 tokenId,address sender, uint256 qty, string memory nonce,string memory convertType) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(tokenId,sender,qty,nonce,convertType))
            )
        );
        return hash;
    }

    /**
     * @dev 生成批量抵押NFT交易的hash值
     * @param tokenIdArray 要被抵押的奖品tokenId数组
     * @param sender 交易触发者
     * @param qty 交易数量
     * @param nonce 交易随机数
     * @param convertType 抵押类型
     * @return 交易的hash值
     */
    function hashBathConvertNFTsTransaction(uint256[] memory tokenIdArray,address sender, uint256 qty, string memory nonce,string memory convertType) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(tokenIdArray,sender, qty, nonce,convertType))
            )
        );
        return hash;
    }

    /**
     * @dev   比较signerAddress是否和根据交易hash生成的signerAddress相同
     * @param hash 交易的hash
     * @param signature 账号签名
     * @return 是否相同
     */
    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
        return signerAddress == recoverSigner(hash,signature);
    }

    /**
     * @dev   转移eth
     * @param _toAddress 要转给的地址
     * @param _amount    要转移的eth数量
     */
    function transferETH(address _toAddress,uint256 _amount)public payable{
        require(hasRole(ETH_TRANSFER_ROLE, msg.sender));
        uint256 contractBalance = address(this).balance;
        require(contractBalance >= _amount,"The ether of be sent must be less than the contractBalance!");
        payable(address(_toAddress)).transfer(_amount);
    }

    /**
     * @dev  提现eth
     */
    function withdraw() public  payable {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        uint256 withdrawETH = address(this).balance -  0.01 ether;
        payable(msg.sender).transfer(withdrawETH);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
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

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}