pragma solidity >=0.6.0 <0.7.0;

import "./RPCProxy.sol";

contract TravelAgency {

    struct Trip {
        address guest;
        uint from;
        uint to;
        uint hotelReservation;
        uint trainReservation;
    }

    address private hotelAddr;
    address private railwayCompanyAddr;
    RPCProxy private blockchainA;
    RPCProxy private blockchainB;
    uint private nextTripId;
    mapping(uint => Trip) public trips;


    constructor(address _blockchainA, address _blockchainB, address _hotelAddr, address _railwayCompanyAddr) public {
        blockchainA = RPCProxy(_blockchainA);
        blockchainB = RPCProxy(_blockchainB);
        hotelAddr = _hotelAddr;
        railwayCompanyAddr = _railwayCompanyAddr;
    }

    function bookTrip(address guest, uint from, uint to) public {
        trips[nextTripId].guest = guest;
        trips[nextTripId].from = from;
        trips[nextTripId].to = to;
        blockchainA
            .contractCall(hotelAddr, nextTripId, "bookHotelCallback")
            .bookRoom(guest, from, to);
        ++nextTripId;
    }

    function bookHotelCallback(uint tripId, bytes result, uint errorCode) public {
        if (errorCode == 0) {
            uint hotelReservation = uint(result);
            trips[tripId].hotelReservation = hotelReservation;
            blockchainB
                .contractCall(railwayCompanyAddr, tripId, "bookTrainCallback")
                .bookTicket(trips[tripId].guest, trips[tripId].from, trips[tripId].to);
        }
        else {
            delete trips[tripId];
            // TODO: emit bookingFailed(tripId);
        }
    }

    function bookTrainCallback(uint tripId, bytes result, uint errorCode) public {
        if (errorCode == 0) {
            trips[tripId].trainReservation = uint(result);
            // TODO: emit event BookingSuccessful(tripId);
        }
        else {
            blockchainA
                .contractCall(hotelAddr, tripId, "cancelHotelCallback")
                .cancelRoom(trips[tripId].hotelReservation);
        }
    }

    function cancelHotelCallback(uint tripId, bytes result, uint errorCode) public {
        if (errorCode == 0) {
            delete trips[tripId];
            // TODO: emit bookingFailed(tripId);
        }
        else {
            // TODO: emit some event
        }
    }

}
