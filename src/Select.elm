module Select exposing
    ( beforeIf, afterIf
    , by, whileLoopBy, head, last
    , all, allBefore, allAfter
    , allBeforeHelp
    )

{-|

@docs beforeIf, afterIf
@docs by, whileLoopBy, head, last
@docs all, allBefore, allAfter

-}

import Types exposing (SelectList(..), loopIndex, reverseAppend, toList)


beforeIf : (a -> Bool) -> SelectList a -> Maybe (SelectList a)
beforeIf pred (SelectList befor a after) =
    splitWhen pred befor
        |> Maybe.map
            (\( nextAfter, next, nextBefore ) ->
                SelectList
                    (List.reverse nextBefore)
                    next
                    (nextAfter ++ (a :: after))
            )


afterIf : (a -> Bool) -> SelectList a -> Maybe (SelectList a)
afterIf pred (SelectList befor a after) =
    splitWhen pred after
        |> Maybe.map
            (\( nextBefore, next, nextAfter ) ->
                SelectList
                    (nextBefore ++ (a :: befor))
                    next
                    (List.reverse nextAfter)
            )


by : Int -> SelectList a -> Maybe (SelectList a)
by n (SelectList before a after) =
    if n > 0 then
        splitAt n after
            |> Maybe.map
                (\( nextBefore, next, nextAfter ) ->
                    SelectList
                        (reverseAppend nextBefore (a :: before))
                        next
                        nextAfter
                )

    else if n < 0 then
        splitAt -n before
            |> Maybe.map
                (\( nextAfter, next, nextBefore ) ->
                    SelectList
                        nextBefore
                        next
                        (reverseAppend nextAfter (a :: after))
                )

    else
        Just <| SelectList before a after


whileLoopBy : Int -> SelectList a -> SelectList a
whileLoopBy n selectList =
    by (loopIndex n selectList) selectList
        |> Maybe.withDefault selectList


head : SelectList a -> SelectList a
head original =
    case toList original of
        a :: after ->
            SelectList [] a after

        -- This branch has never reached
        [] ->
            original


last : SelectList a -> SelectList a
last ((SelectList before a after) as original) =
    case unconsLast after of
        Just ( next, reverseAfter ) ->
            SelectList (reverseAfter ++ (a :: before)) next []

        Nothing ->
            original


all : SelectList a -> List (SelectList a)
all list =
    reverseAppend (allBeforeHelp list) (list :: allAfter list)


allBefore : SelectList a -> List (SelectList a)
allBefore list =
    allBeforeHelp list
        |> List.reverse


allBeforeHelp : SelectList a -> List (SelectList a)
allBeforeHelp (SelectList before a after) =
    case before of
        x :: xs ->
            let
                next =
                    SelectList xs x (a :: after)
            in
            next :: allBeforeHelp next

        [] ->
            []


allAfter : SelectList a -> List (SelectList a)
allAfter (SelectList before a after) =
    case after of
        x :: xs ->
            let
                next =
                    SelectList (a :: before) x xs
            in
            next :: allAfter next

        [] ->
            []



-- helper


splitWhen : (a -> Bool) -> List a -> Maybe ( List a, a, List a )
splitWhen predicate list =
    let
        ( beforeList, maybe, afterList ) =
            List.foldl
                (\a ( before, res, after ) ->
                    case res of
                        Nothing ->
                            if predicate a then
                                ( before, Just a, after )

                            else
                                ( a :: before, Nothing, after )

                        Just _ ->
                            ( before, res, a :: after )
                )
                ( [], Nothing, [] )
                list
    in
    Maybe.map (\target -> ( beforeList, target, afterList )) maybe


splitAt : Int -> List a -> Maybe ( List a, a, List a )
splitAt n list =
    let
        ( before, rest ) =
            ( List.take (n - 1) list, List.drop (n - 1) list )
    in
    case rest of
        a :: after ->
            Just ( before, a, after )

        [] ->
            Nothing


unconsLast : List a -> Maybe ( a, List a )
unconsLast list =
    case List.reverse list of
        [] ->
            Nothing

        last_ :: rest ->
            ( last_, rest )
                |> Just
