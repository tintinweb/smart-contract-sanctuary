pragma solidity ^0.4.13;

contract EtherShare {
    
    uint public count;
    address[] public link; // if there are other EtherShare contracts

    struct oneShare {
        address sender;
        string nickname;
        uint timestamp;
        bool AllowUpdated;
        string content;
    }
    mapping(uint => oneShare[]) public allShare;

    event EVENT(uint ShareID, uint ReplyID);

    function EtherShare() public {
        NewShare("Peilin Zheng", false, "Hello, EtherShare!");  // zhengpeilin.com
    }

    function NewShare(string nickname, bool AllowUpdated, string content) public {
        allShare[count].push(oneShare(msg.sender, nickname, now, AllowUpdated, content)); // add a new share
        EVENT(count,0);
        count++;
    }

    function ReplyShare(uint ShareID, string nickname, bool AllowUpdated, string content) public {
        require(ShareID<count); // reply to a existed share
        allShare[ShareID].push(oneShare(msg.sender, nickname, now, AllowUpdated, content));
        EVENT(ShareID,allShare[ShareID].length-1);
    }

    function Update(uint ShareID, uint ReplyID, string content) public {
        require(msg.sender==allShare[ShareID][ReplyID].sender && allShare[ShareID][ReplyID].AllowUpdated);  // only sender can update the share or reply which is AllowUpdated
        allShare[ShareID][ReplyID].content = content;
        allShare[ShareID][ReplyID].timestamp = now;
        EVENT(ShareID,ReplyID);
    }
}