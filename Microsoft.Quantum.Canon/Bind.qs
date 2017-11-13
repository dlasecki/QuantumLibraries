// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

namespace Microsoft.Quantum.Canon {

    operation Bind1Impl(operations : (Qubit => ())[], target : Qubit) : () {
        body {
            for (idxOperation in 0..Length(operations) - 1) {
                let op = operations[idxOperation]
                op(target)
            }
        }
    }

    /// <summary>
    ///      Given an array of operations acting on a single qubit,
    ///      produces a new operation that
    ///      performs each given operation in sequence.
    /// </summary>
    /// <remark>See Bind1A, Bind1C, and Bind1AC functor variants.</remark>
    function Bind1(operations : (Qubit => ())[]) : (Qubit => ()) {
        return Bind1Impl(operations, _)
    }

    operation Bind1AImpl(operations : (Qubit => () : Adjoint)[], target : Qubit) : () {
        body {
            Bind1Impl(operations, target)
        }
        adjoint {
            // TODO: replace with an implementation based on Reversed : 'T[] -> 'T[]
            //       and AdjointAll : ('T => () : Adjointable)[] -> ('T => () : Adjointable).
            for (idxOperation in Length(operations) - 1..0) {
                let op = (Adjoint operations[idxOperation])
                op(target)
            }
        }
    }

    /// <summary>
    ///      Given an array of operations acting on a single qubit,
    ///      produces a new operation that
    ///      performs each given operation in sequence.
    /// </summary>
    /// <remark>See Bind1, Bind1C, and Bind1AC functor variants.</remark>
    function Bind1A(operations : (Qubit => () : Adjoint)[]) : (Qubit => () : Adjoint) {
        return Bind1AImpl(operations, _)
    }

    operation Bind1CImpl(operations : (Qubit => () : Controlled)[], target : Qubit) : () {
        body {
            Bind1Impl(operations, target)
        }

        controlled (controls) {
            for (idxOperation in 0..Length(operations) - 1) {
                let op = (Controlled operations[idxOperation])
                op(controls, target)
            }
        }
    }

    /// <summary>
    ///      Given an array of operations acting on a single qubit,
    ///      produces a new operation that
    ///      performs each given operation in sequence.
    /// </summary>
    /// <remark>See Bind1, Bind1A, and Bind1AC functor variants.</remark>
    function Bind1C(operations : (Qubit => () : Controlled)[]) : (Qubit => () : Controlled) {
        return Bind1CImpl(operations, _)
    }

    operation Bind1ACImpl(operations : (Qubit => () : Adjoint, Controlled)[], target : Qubit) : () {
        body {
            Bind1Impl(operations, target)
        }

        adjoint {
            (Adjoint Bind1AImpl)(operations, target)
        }
        controlled (controls) {
            (Controlled Bind1CImpl)(controls, (operations, target))
        }

        controlled adjoint (controls) {
            for (idxOperation in Length(operations) - 1..0) {
                let op = (Controlled Adjoint operations[idxOperation])
                op(controls, target)
            }
        }
    }

    /// <summary>
    ///      Given an array of operations acting on a single qubit,
    ///      produces a new operation that
    ///      performs each given operation in sequence.
    /// </summary>
    /// <remark>See Bind1, Bind1A, and Bind1AC functor variants.</remark>
    function Bind1AC(operations : (Qubit => () : Adjoint, Controlled)[]) : (Qubit => () : Adjoint, Controlled) {
        return Bind1ACImpl(operations, _)
    }

}