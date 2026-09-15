@testable import Occupath
import Foundation

func surveyLeg(_ block: SingleLineBlock, on board: WorkingTimetable) throws -> WorkingTimetable {
    try LoopCheck.bind(board).surveyor.record(block)
}

func arrive(_ train: Train, on board: WorkingTimetable) throws -> WorkingTimetable {
    try OccupyBlock.Occupier(train: train, board: board).arrive()
}

func occupierTakes(trainID: UUID, blockID: UUID, on board: WorkingTimetable) throws -> WorkingTimetable {
    try OccupyBlock.bind(trainID: trainID, blockID: blockID, on: board).occupier.take()
}

func holderReturns(blockID: UUID, on board: WorkingTimetable) throws -> WorkingTimetable {
    let context = try HandToken.bind(blockID: blockID, on: board)
    if let holder = context.holder {
        return holder.returnToken()
    }
    return context.issuedToken.release()
}
