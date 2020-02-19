pragma solidity ^0.4.25;

contract HTLC {

    struct ContractData {
        string secret;
        address sender;
        address receiver;
        uint amount;
        uint timelock; // UNIX timestamp seconds - locked UNTIL this time
        bool locked;
        bool unlocked;
        bool rolledback;
    }

    // to lock and unlock counterparty
    string counterpartyHTLCIpath;
    address counterpartyHTLCAddress;

    // recode if you're the initiator
    mapping(string => bool) htlcRoles;

    // initiator is the one who initiates the htlc transaction
    mapping(string => ContractData) initiators;

    // participant is the one who makes the deal with initiator
    mapping(string => ContractData) participants;

    // record all unfinished tasks
    uint head = 0;        // point to the current task to be performed
    uint tail = 0;        // point to the next position for added task
    string[] taskQueue;

    /* to be defined*/
    // function lock(string _hash) external returns (string);
    // function unlock(string _hash) external returns (string);
    // function rollback(string _hash) external returns (string);

    function setCounterpartyHTLCInfo(
        string _counterpartyHTLCIpath,
        string _counterpartyHTLCAddress
    )
    internal
    {
        counterpartyHTLCIpath = _counterpartyHTLCIpath;
        counterpartyHTLCAddress = stringToAddress(_counterpartyHTLCAddress);
    }

    function getCounterpartyHTLCIpath()
    external
    view
    returns (string)
    {
        return counterpartyHTLCIpath;
    }

    function getCounterpartyHTLCAddress()
    external
    view
    returns (string)
    {
        return addressToString(counterpartyHTLCAddress);
    }

    function setRole(
        string _hash,
        string _role
    )
    external
    returns (string)
    {
        if(hasContract(_hash)) {
            return "role exists";
        }

        if(sameString(_role, "true")) {
           htlcRoles[_hash] = true;
        } else {
           htlcRoles[_hash] = false;
        }
        return "success";
    }

    function addInitiator(
        string _hash,
        string _secret,
        string _sender,
        string _receiver,
        string _amount,
        string _timelock
    )
    external
    returns (string)
    {
        if (hasInitiator(_hash)) {
            return "initiator exists";
        }

        initiators[_hash] = ContractData(
            _secret,
            stringToAddress(_sender),
            stringToAddress(_receiver),
            stringToUint(_amount),
            stringToUint(_timelock),
            false,
            false,
            false
        );
        return "success";
    }

    function addParticipant(
        string _hash,
        string _sender,
        string _receiver,
        string _amount,
        string _timelock
    )
    external
    returns (string)
    {
        if (hasParticipant(_hash)) {
            return "participant exists";
        }

        participants[_hash] = ContractData(
            "null",
            stringToAddress(_sender),
            stringToAddress(_receiver),
            stringToUint(_amount),
            stringToUint(_timelock),
            false,
            false,
            false
        );
        return "success";
    }


    function addTask(string _hash)
    external
    returns (string)
    {
        if(!hasContract(_hash)) {
            return "task not exists";
        }

        tail = tail + 1;
        taskQueue.push(_hash);
        return "success";
    }

    function getTask()
    external
    view
    returns (string)
    {
        if(head == tail) {
            return ("null");
        }
        else {
            return (taskQueue[uint(head)]);
        }
    }

    function deleteTask(string _hash)
    external
    returns (string)
    {
        if(head == tail || !sameString(taskQueue[head], _hash)) {
            return "invalid operation";
        }
        head = head + 1;
        return "success";
    }

    function getTaskIndex()
    external
    view
    returns (uint, uint)
    {
        return (head, tail);
    }

    function getSecret(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].secret;
        } else {
            return participants[_hash].secret;
        }
    }

    function setSecret(string _hash, string _secret)
    internal
    {
        if(!htlcRoles[_hash]) {
            participants[_hash].secret = _secret;
        }
    }

    function getSender(string _hash)
    internal
    view
    returns (address)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].sender;
        } else {
            return participants[_hash].sender;
        }
    }

    function getReceiver(string _hash)
    internal
    view
    returns (address)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].receiver;
        } else {
            return participants[_hash].receiver;
        }
    }

    function getAmount(string _hash)
    internal
    view
    returns (uint)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].amount;
        } else {
            return participants[_hash].amount;
        }
    }

    function getTimelock(string _hash)
    internal
    view
    returns (uint)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].timelock;
        } else {
            return participants[_hash].timelock;
        }
    }

    function getLockStatus(string _hash)
    internal
    view
    returns (bool)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].locked;
        } else {
            return participants[_hash].locked;
        }
    }

    function getUnlockStatus(string _hash)
    internal
    view
    returns (bool)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].unlocked;
        } else {
            return participants[_hash].unlocked;
        }
    }

    function getRollbackStatus(string _hash)
    internal
    view
    returns (bool)
    {
        if(htlcRoles[_hash]) {
            return initiators[_hash].rolledback;
        } else {
            return participants[_hash].rolledback;
        }
    }

    function setLockStatus(string _hash)
    internal
    {
        if(htlcRoles[_hash]) {
            initiators[_hash].locked = true;
        } else {
            participants[_hash].locked = true;
        }
    }

    function setUnlockStatus(string _hash)
    internal
    {
        if(htlcRoles[_hash]) {
            initiators[_hash].unlocked = true;
        } else {
            participants[_hash].unlocked = true;
        }
    }

    function setRollbackStatus(string _hash)
    internal
    {
        if(htlcRoles[_hash]) {
            initiators[_hash].rolledback = true;
        } else {
            participants[_hash].rolledback = true;
        }
    }

    // these following functions are just for HTLC scheduler
    function getSelfSender(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            return addressToString(initiators[_hash].sender);
        } else {
            return addressToString(participants[_hash].sender);
        }
    }

    function getCounterpartySender(string _hash)
    external
    view
    returns (string)
    {
        if(!htlcRoles[_hash]) {
            return addressToString(initiators[_hash].sender);
        } else {
            return addressToString(participants[_hash].sender);
        }
    }

    function getSelfReceiver(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            return addressToString(initiators[_hash].receiver);
        } else {
            return addressToString(participants[_hash].receiver);
        }
    }

    function getCounterpartyReceiver(string _hash)
    external
    view
    returns (string)
    {
        if(!htlcRoles[_hash]) {
            return addressToString(initiators[_hash].receiver);
        } else {
            return addressToString(participants[_hash].receiver);
        }
    }

    function getSelfAmount(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            return uintToString(initiators[_hash].amount);
        } else {
            return uintToString(participants[_hash].amount);
        }
    }

    function getCounterpartyAmount(string _hash)
    external
    view
    returns (string)
    {
        if(!htlcRoles[_hash]) {
            return uintToString(initiators[_hash].amount);
        } else {
            return uintToString(participants[_hash].amount);
        }
    }

    function getSelfTimelock(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            return uintToString(initiators[_hash].timelock);
        } else {
            return uintToString(participants[_hash].timelock);
        }
    }

    function getCounterpartyTimelock(string _hash)
    external
    view
    returns (string)
    {
        if(!htlcRoles[_hash]) {
            return uintToString(initiators[_hash].timelock);
        } else {
            return uintToString(participants[_hash].timelock);
        }
    }

    function getSelfLockStatus(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            if(initiators[_hash].locked) {
                return "true";
            } else {
                return "false";
            }
        } else {
            if(participants[_hash].locked) {
                return "true";
            } else {
                return "false";
            }
        }
    }

    function getCounterpartyLockStatus(string _hash)
    external
    view
    returns (string)
    {
        if(!htlcRoles[_hash]) {
            if(initiators[_hash].locked) {
                return "true";
            } else {
                return "false";
            }
        } else {
            if(participants[_hash].locked) {
                return "true";
            } else {
                return "false";
            }
        }
    }

    function getSelfUnlockStatus(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            if(initiators[_hash].unlocked) {
                return "true";
            } else {
                return "false";
            }
        } else {
            if(participants[_hash].unlocked) {
                return "true";
            } else {
                return "false";
            }
        }
    }

    function getCounterpartyUnlockStatus(string _hash)
    external
    view
    returns (string)
    {
        if(!htlcRoles[_hash]) {
            if(initiators[_hash].unlocked) {
                return "true";
            } else {
                return "false";
            }
        } else {
            if(participants[_hash].unlocked) {
                return "true";
            } else {
                return "false";
            }
        }
    }

    function getSelfRollbackStatus(string _hash)
    external
    view
    returns (string)
    {
        if(htlcRoles[_hash]) {
            if(initiators[_hash].rolledback) {
                return "true";
            } else {
                return "false";
            }
        } else {
            if(participants[_hash].rolledback) {
                return "true";
            } else {
                return "false";
            }
        }
    }

    function getCounterpartyRollbackStatus(string _hash)
    external
    view
    returns (string)
    {
        if(!htlcRoles[_hash]) {
            if(initiators[_hash].rolledback) {
                return "true";
            } else {
                return "false";
            }
        } else {
            if(participants[_hash].rolledback) {
                return "true";
            } else {
                return "false";
            }
        }
    }

    function setCounterpartyLockStatus(string _hash)
    external
    {
        if(!htlcRoles[_hash]) {
            initiators[_hash].locked = true;
        } else {
            participants[_hash].locked = true;
        }
    }

    function setCounterpartyUnlockStatus(string _hash)
    external
    {
        if(!htlcRoles[_hash]) {
            initiators[_hash].unlocked = true;
        } else {
            participants[_hash].unlocked = true;
        }
    }

    function setCounterpartyRollbackStatus(string _hash)
    external
    {
        if(!htlcRoles[_hash]) {
            initiators[_hash].rolledback = true;
        } else {
            participants[_hash].rolledback = true;
        }
    }

    // these are utilities
    function hasContract(string _hash)
    internal
    view
    returns (bool)
    {
        return (initiators[_hash].sender != address(0)) &&
               (participants[_hash].sender != address(0));
    }

    function hasInitiator(string _hash)
    internal
    view
    returns (bool)
    {
        return (initiators[_hash].sender != address(0));
    }

    function hasParticipant(string _hash)
    internal
    view
    returns (bool)
    {
        return (participants[_hash].sender != address(0));
    }

    function rightTimelock(string _t0, string _t1)
    internal
    view
    returns (bool)
    {
        uint t0 = stringToUint(_t0);
        uint t1 = stringToUint(_t1);
        return t0 > (t1 + 3600) && t1 > (now + 3600);
    }

    function sameString(string a, string b)
    internal
    pure
    returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function stringToBytes32(string _source)
    internal
    pure
    returns (bytes32 result)
    {
        bytes memory tempEmptyString = bytes(_source);
        if (tempEmptyString.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function bytes32ToString(bytes32 _source)
    internal
    pure
    returns (string)
    {

       bytes memory result = new bytes(_source.length);

       for(uint i = 0; i < _source.length; i++) {

           result[i] = _source[i];
       }

       return string(result);
    }

    function stringToAddress(string _address)
    internal
    pure
    returns (address)
    {
        bytes memory temp = bytes(_address);
        uint160 result = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            result *= 256;
            b1 = uint160(uint8(temp[i]));
            b2 = uint160(uint8(temp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
            }

            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            result += (b1 * 16 + b2);
        }
        return address(result);
    }

    function addressToString(address _address)
    internal
    pure
    returns (string)
    {
        bytes memory result = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte temp = byte(uint8(uint(_address) / (2 ** (8 * (19 - i)))));
            byte b1 = byte(uint8(temp) / 16);
            byte b2 = byte(uint8(temp) - 16 * uint8(b1));
            result[2 * i] = convert(b1);
            result[2 * i + 1] = convert(b2);
        }
        return string(abi.encodePacked("0x", string(result)));
    }

    function convert(byte _byte)
    private
    pure
    returns (byte)
    {
        if (_byte < 10) {
            return byte(uint8(_byte) + 0x30);
        } else {
            return byte(uint8(_byte) + 0x57);
        }
    }

    function uintToString(uint _value)
    internal
    pure
    returns (string)
    {
        bytes32 result;
        if (_value == 0) {
            return "0";
        } else {
            while (_value > 0) {
                result = bytes32(uint(result) / (2 ** 8));
                result |= bytes32(((_value % 10) + 48) * 2 ** (8 * 31));
                _value /= 10;
            }
        }
        return bytes32ToString(result);
    }

    function stringToUint(string _s)
    internal
    pure
    returns (uint)
    {
        bytes memory b = bytes(_s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            if (b[i] >= 48 && b[i] <= 57) {
                result = result * 10 + (uint(b[i]) - 48);
            }
        }
        return result;
    }
}