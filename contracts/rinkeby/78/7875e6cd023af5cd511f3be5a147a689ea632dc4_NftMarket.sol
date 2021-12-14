/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.8.4;


contract NftMarket{
    
    fallback() external payable {}
    receive() external payable {}
    
    address owner;
    address public profitAddress;
    uint256 public transRatio;
    uint256 public adverPrice;
    
    
    ERC20 xybToken = ERC20(0x0C4C2b66A46C94Da95086A18649401f7c8AbDC71);
    
    constructor(address _owner, address _profitAddress, uint256 _transRatio, uint256 _adverPrice){
        owner = _owner;
        profitAddress = _profitAddress;
        transRatio = _transRatio;
        adverPrice = _adverPrice;
    }
    
    struct product{
        address contractAddress;   //nft合约地址对应的合约地址 
        uint256 tokenId;        //nft合约地址对应的tokenId
        string name;        //nft合约地址对应的全称
        string symbol;      //nft合约地址对应的symbol
        string uri;         //tokenId对应的uri
        string headImg;     //tokenId对应的头像主照片
        uint256 price;      //tokenId对应的价格
        bool    upMall;     //tokenId对应的是否上架    
        string info;        //tokenId对应的商品详情
        uint256 nftType;       //nft合约地址对应的种类， 1，艺术品，2，游戏 
        uint256 transNumber;  //tokenId对应的已交易次数 
        address owner;        //tokenId对应的所有者
        bool    isTake;       //是否已经取出 
    }
    
    
    struct Password{
        uint256 tokenId;
        string password;
        address owner; 
    }
    
    
    struct buyOrder{
        address contractAddress;   //合约地址 
        uint256 tokenId;           //买的tokenId
        address buyAddress;        //买家地址 
        address sellAddress;       //卖家地址 
        uint256 price;             //买时价格 
        uint256 buyTime;           //购买时间 
    }
    
    struct sellOrder{
        address contractAddress;   //合约地址 
        uint256 tokenId;           //买的tokenId
        address buyAddress;        //买家地址 
        address sellAddress;       //卖家地址 
        uint256 price;             //买时价格 
        uint256 buyTime;           //购买时间 
    }
    
     struct nftOrder{
        address contractAddress;   //合约地址 
        uint256 tokenId;           //买的tokenId
        address buyAddress;        //买家地址 
        address sellAddress;       //卖家地址 
        uint256 price;             //买时价格 
        uint256 buyTime;           //购买时间 
    }
    
    struct user{
        string username;          //用户名 
        string motto;            //座右铭
        string headImg;          //头像
    }
    
    struct recommendList{
        address owner;
        address contractAddress;
        uint256 tokenId;
        uint256 overTime;   //推荐截止时间 
    }
    
    
    mapping(address => address[])  addressToAddress;   //个人地址对应的上架的合约地址 
    mapping(address => product[])  addressToProduct;    //合约地址对应的商品信息  
    mapping(address => nftOrder[])  addressTonftOrder;   //nft合约地址对应的购买记录  
    mapping(address => buyOrder[])    addressToBuyOrder;      //个人地址对应购买订单记录
    mapping(address => sellOrder[])    addressToSellOrder;      //个人地址对应出售订单记录
    mapping(address => user)       addressToUser;          //个人地址对应个人信息 
    mapping(address => address[])  addressToMyContract;   //个人地址对应的自己发布的合约的地址，非上架的合约地址  
    mapping(uint256 => recommendList[]) typeToRecomendList;    //类型对应推荐商品 
    mapping(address => Password[]) addressToPassword;  //合约地址对应的加密密码
     
     
     
    event setLostRecommendEvent(address _contractAddress, uint256 _tokenId, uint256 _type);
    event setUpMallEvent(address _address, uint256 _tokenId);
    event addMyContractEvent(address _contractAddress);
    event buyNftEvent(address _contractAddress, uint256 _tokenId);
    event addProductEvent(AddProductStruct _product);
    event setPriceEvent(address _address, uint256 _tokenId, uint256 _price);
    event setUriEvent(address _address, uint256 _tokenId, string _uri);
    event setHeadImgEvent(address _address, uint256 _tokenId, string _headImg);
    event updateUserEvent(string _username, string _motto, string _headImg);
    event setRecommendEvent(address _contractAddress, uint256 _tokenId, uint256 _type);
    event userWithDrawEvent(address _contractAddress, uint256 _tokenId);
    event deleteMyContractEvent(address _contractAddress);
    event getPasswordEvent(address _contractAddress, uint256 _tokenId);
    
    
    struct AddProductStruct{
        address contractAddress;   //nft合约地址对应的合约地址 
        uint256 tokenId;        //nft合约地址对应的tokenId
        string name;        //nft合约地址对应的全称
        string symbol;      //nft合约地址对应的symbol
        string uri;         //tokenId对应的uri
        string headImg;     //tokenId对应的头像主照片
        uint256 price;      //tokenId对应的价格
        string info;        //tokenId对应的商品详情
        uint256 nftType;       //nft合约地址对应的种类， 1，艺术品，2，游戏 
        string password;
    } 
    
    function addProduct(AddProductStruct memory _product) payable public{
        
        address _contractAddress = _product.contractAddress;
        uint size;
        assembly { size := extcodesize(_contractAddress) }
        
        require(size > 0, 'it is not a contract address');
        
        product[] memory pp = addressToProduct[_contractAddress];
        
        
        
        bool noTokenId = true;
        uint256 tokenIdNumber;
        
        for(uint256 i = 0; i<pp.length; i++){
            if(pp[i].tokenId == _product.tokenId){
                noTokenId = false;
                tokenIdNumber = i; 
            }
        }
        
        
        
        if(noTokenId == true){
        
            addressToAddress[msg.sender].push(_contractAddress);
            addressToProduct[_contractAddress].push(product(_contractAddress, _product.tokenId, _product.name, _product.symbol, _product.uri, _product.headImg, _product.price, true, _product.info, _product.nftType, 0, msg.sender, false) );
            addressToPassword[_contractAddress].push(Password(_product.tokenId, _product.password, msg.sender));
            
            ERC721 nft = ERC721(_contractAddress);
            nft.transferFrom(msg.sender, address(this), _product.tokenId);
            
            emit addProductEvent(_product);
           
        }else{
            if(pp[tokenIdNumber].isTake == true){
                
                addressToProduct[_contractAddress][tokenIdNumber].isTake = false;
                addressToProduct[_contractAddress][tokenIdNumber].owner = msg.sender;
                addressToProduct[_contractAddress][tokenIdNumber].uri = _product.uri;
                addressToProduct[_contractAddress][tokenIdNumber].headImg = _product.headImg;
                addressToProduct[_contractAddress][tokenIdNumber].price = _product.price;
                addressToProduct[_contractAddress][tokenIdNumber].upMall = true;
                addressToProduct[_contractAddress][tokenIdNumber].info = _product.info;
                
                for(uint256 i=0; i<addressToPassword[_contractAddress].length; i++){
                    if(addressToPassword[_contractAddress][i].tokenId == _product.tokenId){
                        addressToPassword[_contractAddress][i].owner = msg.sender;
                        addressToPassword[_contractAddress][i].password = _product.password;
                    }
                }
                
                ERC721 nft = ERC721(_contractAddress);
                nft.transferFrom(msg.sender, address(this), _product.tokenId);
                
                emit addProductEvent(_product);
              
            }else{
                emit addProductEvent(_product);
                require(1 !=1 , "tokenId is on the shelves");
            }
            
                
        }
            
            
    }
    
    
    //set the product is on the shelves or not on the shelves 
    function setUpMall(address _address, uint256 _tokenId) public{
        bool isOn = false;
        bool isOwner = false;
       
        for(uint256 i = 0; i<addressToProduct[_address].length; i++){
           if(addressToProduct[_address][i].tokenId == _tokenId){
               if(msg.sender == addressToProduct[_address][i].owner){
                    if(addressToProduct[_address][i].upMall == true){
                        setLostRecommend(_address, _tokenId, addressToProduct[_address][i].nftType);
                        
                        addressToProduct[_address][i].upMall = false;
                    }else{
                        if(addressToProduct[_address][i].isTake == false){
                            addressToProduct[_address][i].price = addressToProduct[_address][i].price * 120 /100;
                            addressToProduct[_address][i].upMall = true;
                        }else{
                            addressToProduct[_address][i].price = addressToProduct[_address][i].price * 120 /100;
                            addressToProduct[_address][i].upMall = true;
                            addressToProduct[_address][i].isTake = false;
                            
                            ERC721 nft = ERC721(_address);
                            nft.transferFrom(msg.sender, address(this), _tokenId);
                        }
                        
                    }
                    isOn = true;
                    isOwner = true;
                   
               }else{
                   require(1 !=1 , "you are not the owner");
               }
           }
        }
        emit setUpMallEvent(_address, _tokenId);
        require( isOwner, "you are not the owner");
        require( isOn, "tokenId is not on the shelves");
    }
    
    
    
    //modify price
    function setProducPrice(address _address, uint256 _tokenId, uint256 _price) public{
        for(uint256 i = 0; i<addressToProduct[_address].length; i++){
           if(addressToProduct[_address][i].tokenId == _tokenId){
               if(msg.sender == addressToProduct[_address][i].owner){
                    addressToProduct[_address][i].price = _price;
                    
                    emit setPriceEvent(_address, _tokenId, _price);
                  
               }else{
                   emit setPriceEvent(_address, _tokenId, _price);
                   require(1 !=1 , "you are not the owner");
               }
           }else{
               emit setPriceEvent(_address, _tokenId, _price);
               require(1 !=1 , "tokenId is not on the shelves");
           }
        }
    }
    
    
    //modify uri
    function setProducUri(address _address, uint256 _tokenId, string memory _uri) public{
        for(uint256 i = 0; i<addressToProduct[_address].length; i++){
           if(addressToProduct[_address][i].tokenId == _tokenId){
               if(msg.sender == addressToProduct[_address][i].owner){
                    addressToProduct[_address][i].uri = _uri;
                    
                    emit setUriEvent(_address, _tokenId, _uri);
                   
               }else{
                    emit setUriEvent(_address, _tokenId, _uri);
                    require(1 !=1 , "you are not the owner");
               }
           }else{
                emit setUriEvent(_address, _tokenId, _uri);
                require(1 !=1 , "tokenId is not on the shelves");
           }
        }
    }
    
    
    
    //modify product head picture
    function setProductHeadImg(address _address, uint256 _tokenId, string memory _headImg) public{
        
       for(uint256 i = 0; i<addressToProduct[_address].length; i++){
           if(addressToProduct[_address][i].tokenId == _tokenId){
               if(msg.sender == addressToProduct[_address][i].owner){
                    addressToProduct[_address][i].headImg = _headImg;
                    
                    emit setHeadImgEvent(_address, _tokenId, _headImg);
                   
               }else{
                   emit setHeadImgEvent(_address, _tokenId, _headImg);
                   require(1 !=1 , "you are not the owner");
               }
           }else{
               emit setHeadImgEvent(_address, _tokenId, _headImg);
               require(1 !=1 , "tokenId is not on the shelves");
           }
        }
    }
    
    
    
    //buy product 
    function buyNft(address _contractAddress, uint256 _tokenId) payable public{
        bool isOn = false;
        for(uint256 i = 0; i<addressToProduct[_contractAddress].length; i++){
           if(addressToProduct[_contractAddress][i].tokenId == _tokenId){
               if(addressToProduct[_contractAddress][i].upMall == true){
               uint256 _price = addressToProduct[_contractAddress][i].price;
               address _owner = addressToProduct[_contractAddress][i].owner;
               
              
               addressToProduct[_contractAddress][i].owner = msg.sender;
               addressToProduct[_contractAddress][i].upMall = false;
               addressToProduct[_contractAddress][i].isTake = true;
               addressToProduct[_contractAddress][i].transNumber ++;
               
               addressToBuyOrder[msg.sender].push(buyOrder(_contractAddress, _tokenId, msg.sender, _owner, _price, block.timestamp));
               addressToSellOrder[_owner].push(sellOrder(_contractAddress, _tokenId, msg.sender, _owner, _price, block.timestamp));
                              
               addressTonftOrder[_contractAddress].push(nftOrder(_contractAddress, _tokenId, msg.sender, _owner, _price, block.timestamp));
               
               addressToAddress[msg.sender].push(_contractAddress);
               
               for(uint256 j=0; j<addressToPassword[_contractAddress].length; j++){
                    if(addressToPassword[_contractAddress][j].tokenId == _tokenId){
                        addressToPassword[_contractAddress][j].owner = msg.sender;
                    }
                }
               
               //pop remonded
               for(uint256 h=0; h<typeToRecomendList[addressToProduct[_contractAddress][i].nftType].length; h++){
                   if(typeToRecomendList[addressToProduct[_contractAddress][i].nftType][h].contractAddress == addressToProduct[_contractAddress][i].contractAddress && typeToRecomendList[addressToProduct[_contractAddress][i].nftType][h].tokenId == addressToProduct[_contractAddress][i].tokenId){
                        typeToRecomendList[addressToProduct[_contractAddress][i].nftType][h] = typeToRecomendList[addressToProduct[_contractAddress][i].nftType][typeToRecomendList[addressToProduct[_contractAddress][i].nftType].length -1];
                        typeToRecomendList[addressToProduct[_contractAddress][i].nftType].pop();
                   }
               }
               
               xybToken.transferFrom(msg.sender, address(this), _price);  //to contract
               xybToken.transfer( _owner, _price * (100 - transRatio) / 100);  //to nft owner
               xybToken.transfer( owner, _price * transRatio / 100 /2);  //to this contract owner
               xybToken.transfer( profitAddress, _price * transRatio / 100 /2);  //to this profitAddress
               
               ERC721 nft = ERC721(_contractAddress);
               nft.transferFrom(address(this), msg.sender, _tokenId);
               
               isOn = true;
               emit buyNftEvent(_contractAddress, _tokenId);
               
               }else{
                   emit buyNftEvent(_contractAddress, _tokenId);
                   require(1 !=1 , "tokenId is not upMall");
               }
           }
        }
        
        require( isOn , "tokenId is not on the shelves");
           
    } 
    
    
    function getPassword(address _contractAddress, uint256 _tokenId) public returns(string memory){
        bool isOwner = false;
        for(uint256 i=0; i<addressToPassword[_contractAddress].length; i++){
            if(addressToPassword[_contractAddress][i].owner == msg.sender){
                isOwner = true;
                emit getPasswordEvent(_contractAddress, _tokenId);
                return addressToPassword[_contractAddress][i].password;
            }
        }
        emit getPasswordEvent(_contractAddress, _tokenId);
        require(isOwner, 'you are not the owner');
    }
    
    
    //update persion information 
    function updateUser(string memory _username, string memory _motto, string memory _headImg) public {
        addressToUser[msg.sender].username = _username;
        addressToUser[msg.sender].motto = _motto;
        addressToUser[msg.sender].headImg = _headImg;
        
        emit updateUserEvent(_username, _motto, _headImg);
       
    }
    
    
    //query information of the user  
    function getUser(address _address) public view returns(user memory){
        return addressToUser[_address];
    }
    
    
    //add records of my published contract 
    function addMyContract(address _contractAddress) public{
        uint size;
        assembly { size := extcodesize(_contractAddress) }
        
        require(size > 0, 'it is not a contract address');
        
        bool noOn = true;
        
        for(uint256 i=0; i<addressToMyContract[msg.sender].length; i++){
            if(addressToMyContract[msg.sender][i] == _contractAddress){
                noOn = false;
            }
        }
        
        if(noOn){
            addressToMyContract[msg.sender].push(_contractAddress);
            emit addMyContractEvent(_contractAddress);
        }else{
            emit addMyContractEvent(_contractAddress);
            require(noOn, 'Contract Address is in list');
        }
        
        
        
    
    }
    
    
    function deleteMyContract(address _contractAddress) public{
        for(uint8 i=0; i<addressToMyContract[msg.sender].length; i++){
            if(addressToMyContract[msg.sender][i] == _contractAddress){
                addressToMyContract[msg.sender][i] = addressToMyContract[msg.sender][addressToMyContract[msg.sender].length -1];
                addressToMyContract[msg.sender].pop();
                emit deleteMyContractEvent(_contractAddress);
            }
        }
    }
    
    
    //set the goods is recommended
    function setRecommend(address _contractAddress, uint256 _tokenId, uint256 _type) public{
        bool isOwner = false;
        for(uint256 j=0; j<addressToProduct[_contractAddress].length; j++){
            if(addressToProduct[_contractAddress][j].owner == msg.sender && addressToProduct[_contractAddress][j].tokenId == _tokenId && addressToProduct[_contractAddress][j].contractAddress == _contractAddress){
                isOwner = true;
            }
        }
        
        if(!isOwner){
            emit setRecommendEvent(_contractAddress, _tokenId, _type);
            require(isOwner, "you aren't the owner or tokenId is not on the shelves");
        }
        
        
        bool onList = false;
        
        //check the list number
        uint256 listNumber= 0;
        for(uint256 h = 0; h<typeToRecomendList[_type].length; h++){
            if(typeToRecomendList[_type][h].overTime < block.timestamp){
                listNumber++;
            }
        }
              
        //query the goods is in the recommend list or not
        for(uint256 j=0; j<typeToRecomendList[_type].length; j++){
            if(typeToRecomendList[_type][j].contractAddress == _contractAddress && typeToRecomendList[_type][j].tokenId == _tokenId){
                
                //query recommend time is over or not
                if(typeToRecomendList[_type][j].overTime > block.timestamp){
                    //not over time, add time
                    
                    typeToRecomendList[_type][j].overTime = typeToRecomendList[_type][j].overTime+86400*7 ;
                    
                    xybToken.transferFrom(msg.sender, address(this), adverPrice);   //to this contract
                    
                    emit setRecommendEvent(_contractAddress, _tokenId, _type);
                }else{
                    //is over
                    //check the list is over 10 
                    
                    if((typeToRecomendList[_type].length - listNumber) <10){
                        
                        typeToRecomendList[_type][j].overTime = block.timestamp+86400*7 ;
                        
                        xybToken.transferFrom(msg.sender, address(this), adverPrice);
                        
                        emit setRecommendEvent(_contractAddress, _tokenId, _type);
                        
                    }else{
                        typeToRecomendList[_type][j] = typeToRecomendList[_type][typeToRecomendList[_type].length - 1];
                        typeToRecomendList[_type].pop();
                        
                        emit setRecommendEvent(_contractAddress, _tokenId, _type);
                        require(1 != 1, 'the list is over 10');
                    }
                    
                }
                onList = true;
            }
        }
                
            
        //recommend list do not discover
        if(onList == false){
            if(typeToRecomendList[_type].length - listNumber <10){
                
                typeToRecomendList[_type].push(recommendList(msg.sender, _contractAddress, _tokenId, block.timestamp+86400*7 ));
                
                xybToken.transferFrom(msg.sender, address(this), adverPrice);
                
                emit setRecommendEvent(_contractAddress, _tokenId, _type);
              
            }else{
                emit setRecommendEvent(_contractAddress, _tokenId, _type);
                require(1 != 1, 'the list is over 10');
            }
        } 
                
    }
    
    
    
    //set the goods is recommendeded 
    function setLostRecommend(address _contractAddress, uint256 _tokenId, uint256 _type) public{
        bool isOwner = false;
        for(uint256 j=0; j<addressToProduct[_contractAddress].length; j++){
            if(addressToProduct[_contractAddress][j].owner == msg.sender && addressToProduct[_contractAddress][j].tokenId == _tokenId && addressToProduct[_contractAddress][j].contractAddress == _contractAddress){
                isOwner = true;
            }
        }
        
        if(!isOwner){
            emit setLostRecommendEvent(_contractAddress, _tokenId, _type);
            require(isOwner, "you aren't the owner or tokenId is not on the shelves");
        }
        
       
        //query the goods is in the recommend list or not
        for(uint256 j=0; j<typeToRecomendList[_type].length; j++){
            if(typeToRecomendList[_type][j].contractAddress == _contractAddress && typeToRecomendList[_type][j].tokenId == _tokenId){
                //pop
                typeToRecomendList[_type][j] = typeToRecomendList[_type][typeToRecomendList[_type].length -1];
                typeToRecomendList[_type].pop();
            }
        }
        
        emit setLostRecommendEvent(_contractAddress, _tokenId, _type);

    }
    
    
    
    //withdrow nft
    function userWithDraw(address _contractAddress, uint256 _tokenId) public {
        for(uint256 i = 0; i<addressToProduct[_contractAddress].length; i++){
           if(addressToProduct[_contractAddress][i].tokenId == _tokenId){
              
                require(addressToProduct[_contractAddress][i].owner == msg.sender, 'you are not the owner');
                    
                setLostRecommend(_contractAddress, _tokenId, addressToProduct[_contractAddress][i].nftType );
                   
                addressToProduct[_contractAddress][i] = addressToProduct[_contractAddress][addressToProduct[_contractAddress].length -1];
                addressToProduct[_contractAddress].pop();
                    
                ERC721 nft = ERC721(_contractAddress);
                nft.transferFrom(address(this), msg.sender, _tokenId);
                    
                emit userWithDrawEvent(_contractAddress, _tokenId);
           }
        }
    }


    //owner wi twithdraw nnft
    event ownerWithDrawEvent(address _contractAddress, uint256 _tokenId);
    function ownerWithDraw(address _contractAddress, uint256 _tokenId) public{
        require(msg.sender == owner, 'you are not owner');
        
        ERC721 nft = ERC721(_contractAddress);
        nft.transferFrom(address(this), owner, _tokenId);
        emit ownerWithDrawEvent(_contractAddress, _tokenId);
    }
    
    
    
    //contract owner withdrow xyb and eth
    function contractOwnerWithDraw(uint256 xybNumber, uint256 ethNumber) public {
        require(msg.sender == owner, 'you are not owner');
        
        xybToken.transfer(owner, xybNumber);  //xyb to contract owner
        
        payable(owner).transfer(ethNumber); // eth to contract owner
    }
    
    
    //set Profit Address
    function setProfitAddress(address _profitAddress) public {
        require(msg.sender == owner, 'you are not owner');
        
        profitAddress = _profitAddress;
    }
    
    // set translate ratio
    function setTransRatio(uint256 _transRatio) public {
        require(msg.sender == owner, 'you are not owner');
        
        transRatio = _transRatio;
    }
    
    
    //set advertisement price
    function setAdverPrice(uint256 _adverPrice) public {
        require(msg.sender == owner, 'you are not owner');
        
        adverPrice = _adverPrice;
    }
    
    
    //Query recommend list by type
    function getRecommend(uint256 _type) public view returns(recommendList[] memory) {
       return typeToRecomendList[_type];
    }
    
    
    
    //Get my published contract
    function getMyContract(address _address) public view returns(address[] memory){
        return addressToMyContract[_address];
    }

    
    
    //Get the list of all goods through the user address and return the contract address   
    function getMyProductByMyAddress(address _address) public view returns(address[] memory){
        return addressToAddress[_address];
    }
    
    
    //query all the buyers through the contract address
    function getBuyAddressByContractAddress(address _contractAddress) public view returns(nftOrder[] memory) {
        return addressTonftOrder[_contractAddress];
    }
    
    
    //query goods information through the contract address
    function getGoodsByContractAddress(address _contractAddress) public view returns(product[] memory){
        return addressToProduct[_contractAddress];
    }
    
    
    //query my sales records
    function getMySellOrder(address _address) public view returns(sellOrder[] memory){
        return addressToSellOrder[_address];
    }
    
    
    //query my buying records
    function getMyBuyOrder(address _address) public view returns(buyOrder[] memory){
        return addressToBuyOrder[_address];
    }
    

    
    

    
}




contract ERC20 {
    function transferFrom(address from, address to, uint256 amount) public{}
    function transfer(address recipient, uint256 amount) public {}
}

contract ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) public{}
}