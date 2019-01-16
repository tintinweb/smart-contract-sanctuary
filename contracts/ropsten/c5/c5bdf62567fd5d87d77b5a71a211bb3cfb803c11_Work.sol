pragma solidity >=0.4.21 <0.6.0;


contract Work {

    struct _Work{
        address owner;
        address helper;
        string workId;
        string address_house;
        string type_work;
        uint salary;
        uint time;
    }

    _Work work;

    constructor() public {
        work.owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == work.owner) _;
    }

    function setData(
        address _owner,
        address _helper,
        string _workId,
        string _address_house,
        string _type_work,
        uint _salary,
        uint _time
    ) public {
        work.owner = _owner;
        work.helper = _helper;
        work.workId = _workId;
        work.address_house = _address_house;
        work.type_work = _type_work;
        work.salary = _salary;
        work.time = _time;
    }

    function getData() public view returns(address, address, string, string, string, uint, uint){
        return (work.owner, work.helper, work.workId, work.address_house, work.type_work, work.salary, work.time);
    }

}