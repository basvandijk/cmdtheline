import System.Console.CmdTheLine
import Control.Applicative

import Text.PrettyPrint ( fsep   -- Paragraph fill a list of 'Doc'.
                        , text   -- Make a 'String' into a 'Doc'.
                        , quotes -- Quote a 'Doc'.
                        , (<+>)  -- Glue two 'Doc' together with a space.
                        )

import Data.List ( intersperse )


cmdNames = [ "msg", "usage", "help", "success" ]

failMsg, failUsage, success :: [String] -> Err String
failMsg   strs = Left  . MsgFail   . fsep $ map text strs
failUsage strs = Left  . UsageFail . fsep $ map text strs
success   strs = Right . concat $ intersperse " " strs

help :: String -> Err String
help name
  | any (== name) cmdNames = Left . HelpFail Pager $ Just name
  | name == ""             = Left $ HelpFail Pager Nothing
  | otherwise              =
    Left . UsageFail $ quotes (text name) <+> text "is not the name of a command"

noCmd :: Err String
noCmd = Left $ HelpFail Pager Nothing


def' = def
  { stdOptSection = "COMMON OPTIONS"
  , man =
      [ S "COMMON OPTIONS"
      , P "These options are common to all commands."
      , S "MORE HELP"
      , P "Use '$(mname) $(i,COMMAND) --help' for help on a single command."
      , S "BUGS"
      , P "Email bug reports to <dogWalter@example.com>"
      ]
  }

input :: Term [String]
input = nonEmpty $ posAny [] posInfo
      { argName = "INPUT"
      , argDoc  = "Some input you would like printed to the screen on failure "
               ++ "or success."
      }

cmds :: [( Term String, TermInfo )]
cmds =
  [ ( ret $ failMsg <$> input
    , def' { termName = "msg"
           , termDoc  = "Print a failure message."
           }
    )

  , ( ret $ failUsage <$> input
    , def' { termName = "usage"
           , termDoc  = "Print a usage message."
           }
    )

  , ( ret $ success <$> input
    , def' { termName = "success"
           , termDoc  = "Print a message to the screen"
           }
    )

  , ( ret $ help <$> (pos 0 "" posInfo { argName = "TERM" })
    , def' { termName = "help"
           , termDoc  = "Display help for a command."
           }
    )
  ]

noCmdTerm = ( ret $ pure noCmd
            , def' { termName = "fail"
                   , termDoc  = "A program demoing CmdTheLine's user "
                             ++ "error functionality."
                   }
            )

main = putStrLn =<< execChoice noCmdTerm cmds