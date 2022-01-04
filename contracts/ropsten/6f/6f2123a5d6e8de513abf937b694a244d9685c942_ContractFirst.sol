// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";


contract ContractFirst is ERC20 {
    
    // token distribution
    constructor() {
        _mint(msg.sender , 3000000000000000);
        _mint(address(this) , 17000000000000000);
    }
    
    /// _____________________ submit data

    // @dev the event that generate evry time a user upload a file.
    // @dev use this events to put data in the market.
    event UploadEvent(
        address owner,
        uint256 dataId,
        uint256 gene,
        uint price_Tag
    );

    // @dev the structure of uploaded data.
    // @dev this struct gives you some info. about data.
    // @dev create one of this struct for evry data thats gets upload.
    struct DataUpload{
        uint128 dataId; // Data ID //# uint128 
        address dataOwner; // Data Owner
        uint registrationTime; // Order Registration Time
        uint256 gene; // Generated header with platform
        string ipsfHash; // Encrypted by owner private key
        uint price_Tag;  // data price, initialize and change only by ower
    }

    DataUpload[] public uploadedDatas; //datas-->uploadedDatas

    /// @dev this function calls by data owner whens want to upload data
    /// @dev input argumants are the gene thats create by our app. and
    /// encrypted hash. 
    function uploadNewData(  
        uint256 _gene,
        string memory _ipfsHash,
        uint _priceTag
    )
        public
    {
        uint128 dataId = uint128(uploadedDatas.length);
        uploadedDatas.push(
            DataUpload(
                dataId,
                msg.sender,
                block.timestamp,
                _gene,
                _ipfsHash,
                _priceTag
                )
            );

        emit UploadEvent(msg.sender, dataId, _gene, _priceTag);
    }
    /// _____________________ end of submit data
    /// _____________________send request for dataId

    modifier checkDataId(uint _Data_Number) { 
        DataUpload storage myorder = uploadedDatas[_Data_Number];
        require(_Data_Number == myorder.dataId , "This Data Identifier Is Not Correct");
        _;
    }
    
    modifier notNull(address _address) {
        require(address(0) != _address, "Send To The Zero Address");
        _;
    }

    /// @dev this event generate evrytime a user request for a data.
    /// @dev use this event to send request to data owner.  
    event requestEvent(
        address requesterAddress, //requester Address
        uint256 dataId,   // requested data_ID
        uint256 orderId,   // requested order_ID
        uint price_Tag
        // address dataOwner  // data owner address
        );

    /// @dev the structure of requested data.
    /// @dev create one of this struct when user request for data.
    struct RequestData{
        uint256 orderId; //orderId
        uint256 dataId;  //data_Id
        uint registerationTime; //block timestamp
        address payable requesterAddress; // requester address
        uint price_Tag;  //data price
        int orderStatus; // it has three state: TBD=0, accept=1, reject=2, expire=3.
        string ipfsHash;
		// uint orderAcceptanceTime; // useless
    }

    RequestData[] public requestHistory;

    /// @dev this function send a request to the data_ID owner, 
    /// and ask her/him permision.
    function download(
        uint256 _dataId, //_dataId
        address payable _requesterAddress //_requesterAddress, cant use msg.sender as requester adr
    )
        public 
        checkDataId (_dataId)
        notNull(_requesterAddress)
        
    {
        //load dataId for more information
        DataUpload storage myData = uploadedDatas[_dataId];
        uint  _data_price = myData.price_Tag;

        //transfer required token to smartcontract
        require(_balances[msg.sender] >= (_data_price ), "Your Token Is Not Enough");
        require(msg.sender == _requesterAddress , "Please Enter correct address");

        require(msg.sender != myData.dataOwner , "Are you kidding me?! You are the OWNER. Please try another data Id");
        //create a new request data struct
        uint256 _orderId = requestHistory.length;
        int _orderStatus = 0;
        string memory _ipfsHash = '';
        // uint _orderAcceptanceTime = 0;
        //if(){msg.sender applies once check status then decide what to do}else{}
        requestHistory.push(
            RequestData(
               _orderId,
                _dataId,
                block.timestamp,
                _requesterAddress,
                _data_price,
                _orderStatus,
                _ipfsHash
                // _orderAcceptanceTime
            
            )
        );

        ERC20.transfer(address(this),(_data_price ));

        //emit requestEvent(_contributorAddress ,_dataId ,_orderOwner );
        emit requestEvent(_requesterAddress ,_dataId, _orderId, _data_price);

    }

    /// @dev in the both case, acceptance or rejection, this event generate.
    /// @dev the status of request represente by acceptance variable.
    event requestStatus(
        uint orderId,
        address requesterAddress,
        bool acceptance
        );

    event requestExpired(
        uint orderId,
        address requesterAddress,
        string expired
        );

    modifier OnlyOwner(uint _Data_ID) {
        require(uploadedDatas.length >0, "No data submited yet!");
        DataUpload storage myData = uploadedDatas[_Data_ID];
        require(myData.dataOwner == msg.sender, "You Are Not Owner");
        _;
    }

    /// @dev this function only calls by the owner of data_ID,
    /// and generate requestStatus event.
    function agreement(
        uint _dataId,
        uint _orderId,
        address payable _requesterAddress,
        bool _acceptance,
        string memory _ipfsHash // new hash that encrypted by requester public key

    )
        public 
        OnlyOwner(_dataId)
        checkDataId(_dataId)
    {
        require(uploadedDatas.length >0, "No data submited yet!");
        // load data information for price check
        DataUpload storage myData = uploadedDatas[_dataId]; //#4 if the requester cannt make an offer with different price del. this and use the price in requested data

        // load order for checking some information
        RequestData storage myRequest = requestHistory[_orderId];
        require(myRequest.requesterAddress == _requesterAddress, "Wrong Address!, Not request by this address.");
        require(myRequest.orderStatus == 0, "Seriously, Try another order!");

        if(block.timestamp < (myRequest.registerationTime + 1 hours)) {
            if(_acceptance == true) {
                // the owner accept the offer
                myRequest.ipfsHash = _ipfsHash;
                myRequest.orderStatus = 1;

                _balances[address(this)] = _balances[address(this)] - ( myData.price_Tag );
                _balances[myData.dataOwner] = _balances[myData.dataOwner] + (myRequest.price_Tag);
                emit requestStatus(_dataId,myData.dataOwner, _acceptance); // isn't confusing with #2

            } else {
                // the owner reject the offer
                myRequest.orderStatus = 2;

                _balances[address(this)] = _balances[address(this)] - ( myData.price_Tag );
                _balances[_requesterAddress] = _balances[_requesterAddress] + (myRequest.price_Tag);
                emit requestStatus(_dataId,_requesterAddress, _acceptance); // isn't confusing with #2
            }
            
        } else {
            string memory expired = "Request Expired.";
            myRequest.orderStatus = 3;

            _balances[_requesterAddress] = _balances[_requesterAddress] + (myRequest.price_Tag);
            emit requestExpired(_dataId,_requesterAddress, expired);
        }
    }

    /// @dev the data owner can use this function for update the data's price tag
    function updateDataPrice(
        uint256 _data_ID,
        uint _new_price // new data price

    )
    public
    OnlyOwner(_data_ID)
    {
        DataUpload storage myData = uploadedDatas[_data_ID];
        myData.price_Tag = _new_price;
    }

}