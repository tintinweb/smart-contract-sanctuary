/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

pragma solidity >=0.8.0;

library TransferHelper {

    bytes4 private constant safeBatchTransferFrom = bytes4(keccak256(bytes('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')));
    bytes4 private constant transfer = bytes4(keccak256(bytes('transfer(address, uint256)')));

    function tokentransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(transfer, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function tokenTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function nftTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenid
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, tokenid));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function propssafeBatchTransferFrom(
        address token,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        // bytes4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')));
        (bool success, bytes memory reg) = token.call(abi.encodeWithSelector(safeBatchTransferFrom, from, to, ids, amounts, data));
        require(success && (data.length == 0 || abi.decode(reg, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}
contract XgameExchange {

    address private constant NFTcontract = 0x0b9F79FeAc516dba006033D36F2258394250FFcA;
    address private constant PROPScontract = 0x20a4756DFCCd0b7086dfc9c042aaeebf5d747888;
    address private constant ERC20KOL = 0x3C070A5d1fC192d437d687e370297E3467C5029e;
    address private constant ERC20RH = 0xc054A4373f91e138aE704f06096e863D0Bdc3F8a;
    address private constant Owner = 0x34b4E59a74D607d185B23b940F927f3719ED284E;
    address private feeAddress;
    uint256 Rate;

    struct nftinfo{
        address user;
        uint256 tokenid;
        uint256 price;
        bool online;
    }
    struct propsinfo{
        address user;
        uint256 tokenid;
        uint256 price;
        uint256 amount;
        bool online;
    }
    struct ercinfo{
        address user;
        address contr;
        uint256 amount;
        uint256 price;
        bool online;
    }
    uint256 public nftindex;
    uint256 public propsindex;
    uint256 public ercindex;

    mapping(uint256 => nftinfo) public nftOrder;
    mapping(uint256 => propsinfo) public propsOrder;
    mapping(uint256 => ercinfo) public ercOrder;

    function set_feeAddress(address newaddress) external {
        require(msg.sender == Owner,"you are not Owner");
        feeAddress =  newaddress;
    }

    function fee_divideThousand(uint256 _Rate) external {
        require(_Rate < 1000 , "fee is per thousand");
        require(msg.sender == Owner ,"you are not Owner");
        Rate = _Rate;
    }

    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns (bytes4) {
        require(msg.sender == NFTcontract, "you are not NFTcontract");
        uint256 _nftindex = nftindex; //saving gas
        _nftindex++;
        nftOrder[_nftindex] = nftinfo(from,tokenId,1000,true); //价格先写死为1000;
        nftindex = _nftindex;
        return bytes4(keccak256(bytes('onERC721Received(address,address,uint256,bytes)')));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        require(msg.sender == PROPScontract, "not PROPScontract");
        uint256 _propsindex = propsindex;
        for(uint256 i = 0; i < ids.length; ++i) {
            _propsindex++;
            propsOrder[_propsindex] = propsinfo(from,ids[i],500,values[i],true); //价格先写死为500
        }
        propsindex = _propsindex;
        return 0xbc197c81;
    }

    function nftDownline(uint256 index, uint256 _tokenid, uint256 _price) external{
        require(msg.sender == nftOrder[index].user &&
                nftOrder[index].tokenid == _tokenid &&
                nftOrder[index].price == _price, "Parameter error or Order does not exist");
        TransferHelper.nftTransferFrom(NFTcontract, address(this), msg.sender, _tokenid);
        nftOrder[index].online = false;
    }

    function propsDownline(uint256[] memory index, uint256[] memory ids, uint256[] memory amounts, uint256[] memory prices) external{
        require(index.length == ids.length
                && index.length == amounts.length
                && ids.length == prices.length, "Parameter error");
        for(uint256 i = 0; i < index.length; ++i){
            require(propsOrder[index[i]].user == msg.sender, "Order does not exist");
            require(propsOrder[index[i]].price == prices[i] &&
                    propsOrder[index[i]].tokenid == ids[i] &&
                    propsOrder[index[i]].amount == amounts[i], "Parameter error");
        }
        TransferHelper.propssafeBatchTransferFrom(PROPScontract, address(this), msg.sender, ids, amounts, "");
        for(uint256 i = 0; i < index.length; ++i){
            propsOrder[index[i]].online = false;
        }
    }

    function nftMatchTrade(uint256 index, uint256 _tokenid, uint256 _price) external{
        require(nftOrder[index].user != address(0) &&
                nftOrder[index].tokenid == _tokenid &&
                nftOrder[index].price == _price, "Parameter error or Order does not exist");

        uint256 _rate = Rate;  //saving gas
        uint256 fee = nftOrder[index].price * (_rate/1000);
        uint256 seller = _price - fee;

        TransferHelper.tokenTransferFrom(ERC20KOL, msg.sender, feeAddress, fee);
        TransferHelper.tokenTransferFrom(ERC20KOL, msg.sender, nftOrder[index].user, seller);
        TransferHelper.nftTransferFrom(NFTcontract, address(this), msg.sender, _tokenid);

        nftOrder[index].online = false;
    }

    function propsMatchTrade(uint256[] memory index, uint256[] memory ids, uint256[] memory amounts, uint256[] memory prices) external {
        require(index.length == ids.length &&
                index.length == amounts.length &&
                ids.length == prices.length, "Parameter error");
        for(uint256 i = 0; i < index.length; ++i){
            require(propsOrder[index[i]].user == msg.sender, "Order does not exist");
            require(propsOrder[index[i]].price == prices[i] &&
                    propsOrder[index[i]].tokenid == ids[i] &&
                    propsOrder[index[i]].amount == amounts[i], "Parameter error");
        }
        uint256 rate = Rate; //saving gas
        uint256 fee;
        uint256 seller;
        for(uint256 i = 0; i < index.length ; ++i){
            fee += propsOrder[index[i]].price * (rate/1000);
            seller += propsOrder[index[i]].price * ((1000-rate)/1000);
        }

        TransferHelper.tokenTransferFrom(ERC20RH, msg.sender, feeAddress, fee);
        TransferHelper.tokenTransferFrom(ERC20RH, msg.sender, propsOrder[index[0]].user, seller);
        TransferHelper.propssafeBatchTransferFrom(PROPScontract, address(this), msg.sender, ids, amounts, "");

        for(uint256 i = 0; i < index.length; ++i){
            propsOrder[index[i]].online = false;
        }
    }

    function ercPutline(address _contr, uint256 _amount, uint256 _price) external{
        require(_contr == ERC20KOL || _contr == ERC20RH , "Unsupported contract address");
        TransferHelper.tokenTransferFrom(_contr, msg.sender, address(this), _amount);
        uint256 _ercindex = ercindex;  //saving gas
        _ercindex++;
        ercOrder[_ercindex] = ercinfo(msg.sender,_contr,_amount,_price,true);
        ercindex = _ercindex;
    }

    function ercDownline(address _contr, uint256 index, uint256 _amount, uint256 _price) external{
        require(_contr == ERC20KOL || _contr == ERC20RH , "Unsupported contract address");
        require(msg.sender == ercOrder[index].user &&
                ercOrder[index].contr == _contr &&
                ercOrder[index].amount == _amount &&
                ercOrder[index].price == _price, "Parameter error or Order does not exist");
        TransferHelper.tokentransfer(_contr, ercOrder[index].user, _amount);
        ercOrder[index].online = false;
    }

    function ercMatchTrade(address _contr, uint256 index, uint256 _amount, uint256 _price) external{
        require(_contr == ERC20KOL || _contr == ERC20RH , "Unsupported contract address");
        require(ercOrder[index].user != address(0) &&
                ercOrder[index].contr == _contr &&
                ercOrder[index].amount == _amount &&
                ercOrder[index].price == _price, "Parameter error or Order does not exist");

        uint256 _rate = Rate;  //saving gas
        uint256 fee = ercOrder[index].price * (_rate/1000);
        uint256 seller = _price - fee;

        if (_contr == ERC20KOL) {
            TransferHelper.tokenTransferFrom(ERC20RH, msg.sender, feeAddress, fee);
            TransferHelper.tokenTransferFrom(ERC20RH, msg.sender, ercOrder[index].user, seller);
            TransferHelper.tokentransfer(ERC20KOL, msg.sender, _amount);
        } else{
            TransferHelper.tokenTransferFrom(ERC20KOL, msg.sender, feeAddress, fee);
            TransferHelper.tokenTransferFrom(ERC20KOL, msg.sender, ercOrder[index].user, seller);
            TransferHelper.tokentransfer(ERC20RH, msg.sender, _amount);
        }
        ercOrder[index].online = false;
    }
}