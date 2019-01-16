pragma solidity ^0.4.25;

////設定管理者
contract owned {
    address public owner;

    constructor()public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


//轉換string與byte32
contract byt_str {
    function stringToBytes32(string memory source) pure public returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x) pure public returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

// bitape contract
contract new_bitape is owned, byt_str{

  bool Stop_contract = false;
  
  uint number_index = 0 ;

  struct process {
      address buyer;
      address seller;
      address sensor;
      data_base[] data;
      bool start;
  }

  struct data_base {
    uint8 _stage; //物流階段
    uint8 _report; //異常發報
    uint16 _temperature; //目前溫度
    uint8 _humidity; //目前濕度
    uint8 _vendor; //物流廠商
    uint32 _deliveryman; //送貨員編號
    uint32[2] _location; //位置
    bytes32 _remarks; //備註
    uint32 _time;  //時間

    //追蹤編號 物流階段 異常發報 目前溫度 濕度
    //物流廠商 送貨員編號 位置查詢 備註 時間
  }



  mapping (uint => process) all_data;
  //"服務編號" => 數組 => data結構體

  event Start(address indexed sensor, address seller, uint number);
  event Binding(address indexed seller, address indexed buyer);
  event Update(address indexed sensor, uint indexed _number);
  event Stop(address indexed sensor, uint number);

//管理權限

  function set_stop_contract(bool _stop) public onlyOwner{
      Stop_contract = _stop;
  }

//啟用結束服務function
  
  function start(uint32[2] _location, uint32 _time) public{
      
    require(Stop_contract == false);
    uint _number = number_index;
    all_data[_number].start = true;

    all_data[_number].sensor = msg.sender ;

    data_base memory _data = data_base(
        0, //物流階段
        0, //異常發報
        0, //目前溫度
        0, //目前濕度
        0, //物流廠商
        0, //送貨員編號
        _location , //位置, //位置
        0x0, //備註
        _time  //時間;
        );
        all_data[_number].data.push(_data);

    number_index += 1;
    
    emit Start(msg.sender, 0x0, _number);
  }
  
   function start(address _seller, uint32[2] _location, uint32 _time) public{
      
    require(Stop_contract == false);
    uint _number = number_index;
    all_data[_number].start = true;

    all_data[_number].seller = _seller ;
    all_data[_number].sensor = msg.sender ;

    data_base memory _data = data_base(
        0, //物流階段
        0, //異常發報
        0, //目前溫度
        0, //目前濕度
        0, //物流廠商
        0, //送貨員編號
        _location , //位置, //位置
        0x0, //備註
        _time  //時間;
        );
        all_data[_number].data.push(_data);

    number_index += 1;
    
    emit Start(msg.sender, _seller, _number);
  }
  
  function binding(uint _number, address _buyer ,uint32 _time)public{
    require(Stop_contract == false);
    require(msg.sender == all_data[_number].seller);
    
    all_data[_number].buyer = _buyer;

    data_base memory _data = data_base(
        0, //物流階段
        0, //異常發報
        0, //目前溫度
        0, //目前濕度
        0, //物流廠商
        0, //送貨員編號
        [uint32(0),uint32(0)] , //位置, //位置
        0x0, //備註
        _time  //時間;
        );
        all_data[_number].data.push(_data);

    number_index += 1;
    
    emit Binding(all_data[_number].seller, all_data[_number].buyer);
  }
  
  function stop(uint _number, uint32[2] _location, uint32 _time) public{
      require(all_data[_number].start == true);
      require(all_data[_number].sensor == msg.sender);
      
        data_base memory _data = data_base(
        255, //物流階段
        0, //異常發報
        0, //目前溫度
        0, //目前濕度
        0, //物流廠商
        0, //送貨員編號
        _location, //位置
        0x0, //備註
        _time  //時間;
        );
        all_data[_number].data.push(_data);
        all_data[_number].start = false;

        emit Stop(msg.sender, _number);
  }

//上傳資料function
  function update_event(
    uint _number, //追蹤編號
    uint8 _stage, //物流階段
    uint8 _report, //異常發報
    uint16 _temperature, //目前溫度
    uint8 _humidity, //目前濕度
    uint8 _vendor, //物流廠商
    uint32 _deliveryman, //送貨員編號
    uint32[2] _location, //位置
    string _remarks_str, //備註
    uint32 _time  //時間
  ) public{
    require(msg.sender == all_data[_number].sensor);
    require(all_data[_number].start == true);

    bytes32 _remarks_byt = stringToBytes32(_remarks_str);

    data_base memory _data = data_base(
        _stage, //物流階段
        _report, //異常發報
        _temperature, //目前溫度
        _humidity, //目前濕度
        _vendor, //物流廠商
        _deliveryman, //送貨員編號
        _location, //位置
        _remarks_byt, //備註
        _time  //時間;
        );
    all_data[_number].data.push(_data);
    
    emit Update(msg.sender, _number);
  }

//查詢用function

  function inquire_length(uint _number) public view returns(uint){
      
      uint _length = all_data[_number].data.length;
      
      if(msg.sender == all_data[_number].buyer
      || msg.sender == all_data[_number].seller){
          return _length;
      }
      else if(msg.sender == all_data[_number].sensor || msg.sender == owner){
          return _length;
      }
      else{
          return 0;
      }
 
    //查詢該追蹤編號擁有幾筆data
  }


  function inquire(uint _number, uint _sort) public view returns(
    uint8 _stage, //物流階段
    uint8 _report, //異常發報
    uint16 _temperature, //目前溫度
    uint8 _humidity, //目前濕度
    uint8 _vendor, //物流廠商
    uint32 _deliveryman, //送貨員編號
    uint32[2] _location, //位置
    string _remarks, //備註
    uint32 _time  //時間
        ){
            
      bool can_view;
      
      if(msg.sender == all_data[_number].buyer
      || msg.sender == all_data[_number].seller){
          can_view = true;
      }
      else if(msg.sender == all_data[_number].sensor || msg.sender == owner){
          can_view = true;
      }
      
      if(can_view == true){
          bytes32  _remarks_byt = all_data[_number].data[_sort]._remarks;
          string memory  _remarks_str = bytes32ToString(_remarks_byt);

          _stage = all_data[_number].data[_sort]._stage;
          _report = all_data[_number].data[_sort]._report;
          _temperature = all_data[_number].data[_sort]._temperature;
          _humidity = all_data[_number].data[_sort]._humidity;
          _vendor = all_data[_number].data[_sort]._vendor;
          _deliveryman = all_data[_number].data[_sort]._deliveryman;
          _location = all_data[_number].data[_sort]._location;
          _remarks = _remarks_str;
          _time = all_data[_number].data[_sort]._time;
      }
      else{}
  }


 }